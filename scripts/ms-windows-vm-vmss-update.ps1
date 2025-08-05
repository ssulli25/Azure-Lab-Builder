param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId
)

az account set --subscription $SubscriptionId

# Update Windows VMs
$windowsVMs = az vm list --query "[?storageProfile.osDisk.osType=='Windows']" -o json | ConvertFrom-Json
foreach ($vm in $windowsVMs) {
    Write-Host "Updating Windows VM: $($vm.name) in $($vm.resourceGroup)"
    az vm run-command invoke `
        --resource-group $vm.resourceGroup `
        --name $vm.name `
        --command-id RunPowerShellScript `
        --scripts "Install-Module -Name PSWindowsUpdate -Force; Import-Module PSWindowsUpdate; Get-WindowsUpdate -AcceptAll -Install -AutoReboot"
}

# Update Windows VMSS instances
$vmssList = az vmss list --query "[?virtualMachineProfile.storageProfile.osDisk.osType=='Windows']" -o json | ConvertFrom-Json
foreach ($vmss in $vmssList) {
    Write-Host "Updating Windows VMSS: $($vmss.name) in $($vmss.resourceGroup)"
    $instanceIds = az vmss list-instances --resource-group $vmss.resourceGroup --name $vmss.name --query "[].instanceId" -o tsv
    foreach ($id in $instanceIds) {
        az vmss run-command invoke `
            --resource-group $vmss.resourceGroup `
            --name $vmss.name `
            --instance-id $id `
            --command-id RunPowerShellScript `
            --scripts "Install-Module -Name PSWindowsUpdate -Force; Import-Module PSWindowsUpdate; Get-WindowsUpdate -AcceptAll -Install -AutoReboot"
    }
}