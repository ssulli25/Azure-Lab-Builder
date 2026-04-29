# SLS data-tier CSE bootstrap. Firewall (5022/1434/ICMP), ops dir, dbatools.
# Sized to fit Windows CSE commandToExecute (cmd.exe ~8KB cap, encoded x2.67).
$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
Write-Output 'sls-bootstrap start'
$rules=@(
@{N='SLS-SQL-AG-TCP-5022';D='SLS SQL AG (TCP 5022)';P='TCP';L=5022},
@{N='SLS-SQL-Browser-UDP';D='SLS SQL Browser (UDP 1434)';P='UDP';L=1434})
foreach($r in $rules){
 if(Get-NetFirewallRule -Name $r.N -ErrorAction SilentlyContinue){Remove-NetFirewallRule -Name $r.N}
 New-NetFirewallRule -Name $r.N -DisplayName $r.D -Direction Inbound -Action Allow -Protocol $r.P -LocalPort $r.L -Profile Any|Out-Null}
if(Get-NetFirewallRule -Name 'SLS-ICMPv4-In' -ErrorAction SilentlyContinue){Remove-NetFirewallRule -Name 'SLS-ICMPv4-In'}
New-NetFirewallRule -Name 'SLS-ICMPv4-In' -DisplayName 'SLS ICMPv4 Echo' -Direction Inbound -Action Allow -Protocol ICMPv4 -IcmpType 8 -Profile Any|Out-Null
New-Item -Path 'C:\opt\sls-data' -ItemType Directory -Force|Out-Null
Write-Output 'installing dbatools'
[Net.ServicePointManager]::SecurityProtocol=[Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$root='C:\Program Files\WindowsPowerShell\Modules'
$j=Start-Job -ScriptBlock{param($r)
 $ErrorActionPreference='Stop'
 [Net.ServicePointManager]::SecurityProtocol=[Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
 $u='https://www.powershellgallery.com/api/v2/package/dbatools'
 $z=Join-Path $env:TEMP 'dbatools.nupkg.zip'
 $d=Join-Path $r 'dbatools'
 if(Test-Path $d){Remove-Item $d -Recurse -Force}
 New-Item -ItemType Directory -Path $d -Force|Out-Null
 Invoke-WebRequest -Uri $u -OutFile $z -UseBasicParsing
 Expand-Archive -Path $z -DestinationPath $d -Force
 Remove-Item $z -Force
 foreach($k in '_rels','package','[Content_Types].xml','dbatools.nuspec'){
  $p=Join-Path $d $k;if(Test-Path $p){Remove-Item $p -Recurse -Force}}} -ArgumentList $root
if(-not(Wait-Job -Job $j -Timeout 600)){Stop-Job $j;Remove-Job $j -Force;throw 'dbatools install timed out'}
Receive-Job $j;Remove-Job $j
Write-Output 'sls-bootstrap done'
