<#
.SYNOPSIS
  Data-tier OS bootstrap, run as a CustomScriptExtension after the SQL IaaS
  Agent extension has finished installing/configuring SQL.

.DESCRIPTION
  This script intentionally does NOT touch:
    - SQL services (Set-Service / Start-Service) — owned by the SQL IaaS extension.
    - HADR / Always On AG flag — enabled at the SQL VM level later, not here.
    - Disk formatting / drive letters — handled by the SQL IaaS extension via
      storage_configuration on the azurerm_mssql_virtual_machine resource.

  It only does OS-level things the SQL extension doesn't cover:
    - Windows Firewall: SQL (1433), AG mirroring (5022), SQL Browser (1434/UDP), ICMPv4.
    - Operational directory C:\opt\sls-data.
    - Azure + dbatools PowerShell modules (used by future operational scripts).
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

Write-Output '--- SLS data-tier bootstrap starting ---'

#--------------------------------------------------------------------------
# 1. Windows Firewall rules
#--------------------------------------------------------------------------
Write-Output '[1/3] Configuring Windows Firewall rules'

$firewallRules = @(
    @{ Name = 'SLS-SQL-TCP-1433';    DisplayName = 'SLS SQL Server (TCP 1433)';       Protocol = 'TCP'; LocalPort = 1433 },
    @{ Name = 'SLS-SQL-AG-TCP-5022'; DisplayName = 'SLS SQL AG Mirroring (TCP 5022)';  Protocol = 'TCP'; LocalPort = 5022 },
    @{ Name = 'SLS-SQL-Browser-UDP'; DisplayName = 'SLS SQL Browser (UDP 1434)';       Protocol = 'UDP'; LocalPort = 1434 }
)

foreach ($rule in $firewallRules) {
    if (Get-NetFirewallRule -Name $rule.Name -ErrorAction SilentlyContinue) {
        Remove-NetFirewallRule -Name $rule.Name
    }
    New-NetFirewallRule `
        -Name $rule.Name `
        -DisplayName $rule.DisplayName `
        -Direction Inbound `
        -Action Allow `
        -Protocol $rule.Protocol `
        -LocalPort $rule.LocalPort `
        -Profile Any | Out-Null
    Write-Output "  Allowed inbound $($rule.Protocol)/$($rule.LocalPort) ($($rule.DisplayName))"
}

if (Get-NetFirewallRule -Name 'SLS-ICMPv4-In' -ErrorAction SilentlyContinue) {
    Remove-NetFirewallRule -Name 'SLS-ICMPv4-In'
}
New-NetFirewallRule `
    -Name 'SLS-ICMPv4-In' `
    -DisplayName 'SLS ICMPv4 Echo Request' `
    -Direction Inbound `
    -Action Allow `
    -Protocol ICMPv4 `
    -IcmpType 8 `
    -Profile Any | Out-Null
Write-Output '  Allowed inbound ICMPv4 echo'

#--------------------------------------------------------------------------
# 2. Operational directory
#--------------------------------------------------------------------------
Write-Output '[2/3] Creating C:\opt\sls-data'
New-Item -Path 'C:\opt\sls-data' -ItemType Directory -Force | Out-Null

#--------------------------------------------------------------------------
# 3. Install operational PowerShell modules (direct .nupkg from PSGallery)
#
#    Bypasses PowerShellGet 1.0.0.1 / Install-PackageProvider, both of which
#    hang silently on stock WS2022 with no per-call timeout. Each module is
#    downloaded as a .nupkg (zip), extracted into the system module path, and
#    NuGet packaging metadata is stripped. Wrapped in Start-Job + Wait-Job so
#    a hang fails fast.
#
#    Az.Sql/Az.Storage/Az.Compute all depend on Az.Accounts; install first.
#--------------------------------------------------------------------------
Write-Output '[3/3] Installing PowerShell modules (direct .nupkg from PSGallery)'

[Net.ServicePointManager]::SecurityProtocol =
    [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$moduleRoot = 'C:\Program Files\WindowsPowerShell\Modules'
$modules = @('Az.Accounts', 'Az.Sql', 'Az.Storage', 'Az.Compute', 'dbatools')

foreach ($m in $modules) {
    Write-Output "  Installing $m ..."
    $job = Start-Job -ScriptBlock {
        param($name, $root)
        $ErrorActionPreference = 'Stop'
        [Net.ServicePointManager]::SecurityProtocol =
            [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

        $url  = "https://www.powershellgallery.com/api/v2/package/$name"
        $zip  = Join-Path $env:TEMP "$name.nupkg.zip"
        $dest = Join-Path $root $name

        if (Test-Path $dest) {
            Remove-Item -Path $dest -Recurse -Force
        }
        New-Item -ItemType Directory -Path $dest -Force | Out-Null

        Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
        Expand-Archive  -Path $zip -DestinationPath $dest -Force
        Remove-Item     -Path $zip -Force

        foreach ($junk in '_rels', 'package', '[Content_Types].xml', "$name.nuspec") {
            $p = Join-Path $dest $junk
            if (Test-Path $p) { Remove-Item -Path $p -Recurse -Force }
        }
    } -ArgumentList $m, $moduleRoot

    if (-not (Wait-Job -Job $job -Timeout 600)) {
        Stop-Job -Job $job
        Remove-Job -Job $job -Force
        throw "Install of '$m' timed out after 10 minutes"
    }

    Receive-Job -Job $job
    Remove-Job -Job $job
    Write-Output "  Installed $m"
}

Write-Output '--- SLS data-tier bootstrap complete ---'
