param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId
)

az account set --subscription $SubscriptionId

# Update Ubuntu VMs
$ubuntuVMs = az vm list --query "[?storageProfile.osDisk.osType=='Linux']" -o json | ConvertFrom-Json
foreach ($vm in $ubuntuVMs) {
    Write-Host "Updating Ubuntu VM: $($vm.name) in $($vm.resourceGroup)"
    az vm run-command invoke `
        --resource-group $vm.resourceGroup `
        --name $vm.name `
        --command-id RunShellScript `
        --scripts "sudo apt update && sudo apt upgrade -y"
}

# Update Ubuntu VMSS instances
$vmssList = az vmss list --query "[?virtualMachineProfile.storageProfile.osDisk.osType=='Linux']" -o json | ConvertFrom-Json
foreach ($vmss in $vmssList) {
    Write-Host "Updating Ubuntu VMSS: $($vmss.name) in $($vmss.resourceGroup)"
    $instanceIds = az vmss list-instances --resource-group $vmss.resourceGroup --name $vmss.name --query "[].instanceId" -o tsv
    foreach ($id in $instanceIds) {
        az vmss run-command invoke `
            --resource-group $vmss.resourceGroup `
            --name $vmss.name `
            --instance-id $id `
            --command-id RunShellScript `
            --scripts "sudo apt update && sudo apt upgrade -y"
    }
}