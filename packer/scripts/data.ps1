<#
.SYNOPSIS
  Packer provisioning script for the SLS data tier image.

.DESCRIPTION
  Runs against an Azure Marketplace SQL Server 2022 Developer / Windows Server 2022
  VM (publisher: MicrosoftSQLServer, offer: sql2022-ws2022, sku: sqldev-gen2).

  SQL Server is already installed by the marketplace SKU. This script:
    - Verifies SQL services are present and sets them to auto-start.
    - Enables the Always On Availability Groups feature flag (takes effect on next service restart).
    - Opens Windows Firewall ports needed by SQL, AG mirroring, and operational tooling.
    - Creates C:\opt\sls-data (parity with /opt/sls-data on Linux tiers).
    - Installs Az and dbatools PowerShell modules.

  This script is sysprep-safe: no per-instance state is written.
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

Write-Output '--- SLS data-tier image build starting ---'

#--------------------------------------------------------------------------
# 1. Sanity check: SQL Server services exist
#--------------------------------------------------------------------------
Write-Output '[1/6] Verifying SQL Server services'
$requiredServices = @('MSSQLSERVER', 'SQLSERVERAGENT', 'SQLBrowser')
foreach ($svc in $requiredServices) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($null -eq $service) {
        throw "Required SQL service '$svc' not found. Wrong marketplace SKU?"
    }
    Write-Output "  Found service: $svc (status: $($service.Status))"
}

#--------------------------------------------------------------------------
# 2. Set SQL services to auto-start
#--------------------------------------------------------------------------
Write-Output '[2/6] Setting SQL services to Automatic start'
Set-Service -Name 'MSSQLSERVER'    -StartupType Automatic
Set-Service -Name 'SQLSERVERAGENT' -StartupType Automatic
Set-Service -Name 'SQLBrowser'     -StartupType Automatic

#--------------------------------------------------------------------------
# 3. Enable Always On Availability Groups feature flag
#    Idempotent — sets HADR enabled on the SQL service.
#    Takes effect after MSSQLSERVER restart (which happens at deploy time).
#--------------------------------------------------------------------------
Write-Output '[3/6] Enabling Always On Availability Groups feature flag'
try {
    Import-Module SQLPS -DisableNameChecking -ErrorAction Stop
    $instance = (Get-Item 'SQLSERVER:\SQL\localhost\DEFAULT')
    if (-not $instance.IsHadrEnabled) {
        Enable-SqlAlwaysOn -ServerInstance 'localhost' -Force -NoServiceRestart
        Write-Output '  AG feature flag enabled (will activate on next SQL service restart).'
    } else {
        Write-Output '  AG feature flag already enabled.'
    }
}
catch {
    Write-Warning "  Could not enable AG flag via SQLPS: $_"
    Write-Warning '  AG can be enabled at deploy time. Continuing.'
}

#--------------------------------------------------------------------------
# 4. Windows Firewall rules
#--------------------------------------------------------------------------
Write-Output '[4/6] Configuring Windows Firewall rules'

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
# 5. Operational directory
#--------------------------------------------------------------------------
Write-Output '[5/6] Creating C:\opt\sls-data'
New-Item -Path 'C:\opt\sls-data' -ItemType Directory -Force | Out-Null

#--------------------------------------------------------------------------
# 6. Install operational PowerShell modules
#--------------------------------------------------------------------------
Write-Output '[6/6] Installing PowerShell modules (Az, dbatools)'

# Trust PSGallery so Install-Module is non-interactive
if ((Get-PSRepository -Name 'PSGallery').InstallationPolicy -ne 'Trusted') {
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
}

# NuGet provider needed for Install-Module
Install-PackageProvider -Name NuGet -Force -Scope AllUsers | Out-Null

Install-Module -Name Az       -Scope AllUsers -Force -AllowClobber -SkipPublisherCheck
Install-Module -Name dbatools -Scope AllUsers -Force -AllowClobber -SkipPublisherCheck

Write-Output '--- SLS data-tier image build complete ---'
