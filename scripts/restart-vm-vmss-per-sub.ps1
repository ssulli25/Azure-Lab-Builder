# Restart-AllAzureVMs.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId
)

# Set the subscription context
Set-AzContext -SubscriptionId $SubscriptionId

# Restart all Virtual Machines
$vms = Get-AzVM
foreach ($vm in $vms) {
    Write-Host "Restarting VM: $($vm.Name) in resource group: $($vm.ResourceGroupName)"
    Restart-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force
}

# Restart all Virtual Machine Scale Sets
$vmssList = Get-AzVmss
foreach ($vmss in $vmssList) {
    Write-Host "Restarting VMSS: $($vmss.Name) in resource group: $($vmss.ResourceGroupName)"
    Restart-AzVmss -ResourceGroupName $vmss.ResourceGroupName -VMScaleSetName $vmss.Name -Force
}