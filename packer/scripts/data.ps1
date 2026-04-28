<#
.SYNOPSIS
  Packer provisioning script for the SLS data tier image.

.DESCRIPTION
  Runs against an Azure Marketplace SQL Server 2022 Developer / Windows Server 2022
  VM (publisher: MicrosoftSQLServer, offer: sql2022-ws2022, sku: sqldev-gen2).

  SQL Server is already installed by the marketplace SKU. This script:
    - Verifies SQL services are present.
    - Sets SQL services to MANUAL start (see step 2 comment for why).
    - Opens Windows Firewall ports needed by SQL, AG mirroring, and operational tooling.
    - Creates C:\opt\sls-data and registers a first-boot scheduled task that
      starts SQL after the VM Agent reports Ready.
    - Installs Az and dbatools PowerShell modules.

  This script is sysprep-safe: SQL services are set to Manual (not
  Automatic), the AG feature flag is NOT enabled at image-build time,
  and a self-deleting first-boot scheduled task brings SQL up after
  the Azure VM Agent reports Ready on the deployed VM.
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

Write-Output '--- SLS data-tier image build starting ---'

#--------------------------------------------------------------------------
# 1. Sanity check: SQL Server services exist
#--------------------------------------------------------------------------
Write-Output '[1/5] Verifying SQL Server services'
$requiredServices = @('MSSQLSERVER', 'SQLSERVERAGENT', 'SQLBrowser')
foreach ($svc in $requiredServices) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($null -eq $service) {
        throw "Required SQL service '$svc' not found. Wrong marketplace SKU?"
    }
    Write-Output "  Found service: $svc (status: $($service.Status))"
}

#--------------------------------------------------------------------------
# 2. Set SQL services to Manual start
#    Critical: the marketplace SQL2022 image bakes @@SERVERNAME, instance
#    SIDs, and other per-instance state into the install. After sysprep+
#    capture, when this image deploys to a new VM, Windows specialization
#    renames the host. If MSSQLSERVER is set to Automatic it tries to
#    start during first boot with the OLD hostname, hangs in error
#    recovery, and starves the Azure VM Agent — which then never reports
#    Ready and ARM times out (OSProvisioningTimedOut after 40 min).
#
#    Setting services to Manual lets the VM Agent come up cleanly. A
#    self-deleting first-boot scheduled task (registered in step [4/5])
#    flips them back to Automatic and starts them after the agent is
#    settled.
#--------------------------------------------------------------------------
Write-Output '[2/5] Setting SQL services to Manual start'
Set-Service -Name 'MSSQLSERVER'    -StartupType Manual
Set-Service -Name 'SQLSERVERAGENT' -StartupType Manual
Set-Service -Name 'SQLBrowser'     -StartupType Manual

#--------------------------------------------------------------------------
# 3. Windows Firewall rules
#--------------------------------------------------------------------------
Write-Output '[3/5] Configuring Windows Firewall rules'

$firewallRules = @(
    @{ Name = 'SLS-SQL-TCP-1433';    DisplayName = 'SLS SQL Server (TCP 1433)';      Protocol = 'TCP'; LocalPort = 1433 },
    @{ Name = 'SLS-SQL-AG-TCP-5022'; DisplayName = 'SLS SQL AG Mirroring (TCP 5022)'; Protocol = 'TCP'; LocalPort = 5022 },
    @{ Name = 'SLS-SQL-Browser-UDP'; DisplayName = 'SLS SQL Browser (UDP 1434)';      Protocol = 'UDP'; LocalPort = 1434 }
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

# ICMPv4 echo (parity with Linux NSG rule "Allow-ICMP-App-Tier")
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
# 4. Operational directory + first-boot SQL enablement task
#
#    The first-boot scheduled task waits 30s after VM startup (so the
#    Azure VM Agent has time to report Ready), then flips SQL services
#    back to Automatic and starts them. The task self-deletes after
#    running, so subsequent reboots are no-ops.
#--------------------------------------------------------------------------
Write-Output '[4/5] Creating C:\opt\sls-data and registering first-boot SQL task'

New-Item -Path 'C:\opt\sls-data' -ItemType Directory -Force | Out-Null

$firstBootScript = @'
Start-Sleep -Seconds 30
Set-Service -Name 'MSSQLSERVER'    -StartupType Automatic
Set-Service -Name 'SQLSERVERAGENT' -StartupType Automatic
Set-Service -Name 'SQLBrowser'     -StartupType Automatic
Start-Service -Name 'MSSQLSERVER', 'SQLSERVERAGENT', 'SQLBrowser'
schtasks.exe /Delete /TN 'SLS-FirstBoot-EnableSql' /F
'@

$firstBootPath = 'C:\opt\sls-data\firstboot-enable-sql.ps1'
Set-Content -Path $firstBootPath -Value $firstBootScript -Encoding ASCII

$action    = New-ScheduledTaskAction `
                 -Execute 'PowerShell.exe' `
                 -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$firstBootPath`""
$trigger   = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal `
                 -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
                 -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName 'SLS-FirstBoot-EnableSql' `
    -Action $action -Trigger $trigger -Principal $principal -Settings $settings `
    -Description 'Enable and start SQL services on first boot of a generalized image; self-deletes after first run.' `
    -Force | Out-Null

Write-Output '  Registered scheduled task SLS-FirstBoot-EnableSql'

#--------------------------------------------------------------------------
# 5. Install operational PowerShell modules (direct .nupkg download)
#
#    Bypasses PowerShellGet 1.0.0.1 and Install-PackageProvider entirely
#    (both hang silently on stock WS2022 with no per-call timeout, and
#    Install-Module silently waits for a license prompt that never arrives
#    on a non-interactive WinRM session).
#
#    Each module is downloaded from PSGallery as a .nupkg (zip), extracted
#    into the system module path, and the NuGet packaging metadata stripped.
#    Wrapped in Start-Job + Wait-Job -Timeout so a hang fails fast.
#
#    Az dependency note: Az.Sql, Az.Storage, and Az.Compute all depend on
#    Az.Accounts, so install Az.Accounts first.
#--------------------------------------------------------------------------
Write-Output '[5/5] Installing PowerShell modules (direct .nupkg from PSGallery)'

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

        # Strip NuGet packaging metadata so PowerShell sees a clean module dir
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

Write-Output '--- SLS data-tier image build complete ---'
