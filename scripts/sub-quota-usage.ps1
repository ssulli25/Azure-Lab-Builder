param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    [Parameter(Mandatory=$true)]
    [string]$Location
)

az account set --subscription $SubscriptionId

Write-Host ""

Write-Host "=== VM Quota Usage ==="
az vm list-usage --location $Location -o table

Write-Host ""
Write-Host ""

Write-Host "=== Storage Quota Usage ==="
az storage account show-usage --location $Location -o table

Write-Host ""
Write-Host ""

Write-Host "=== Resource Groups in Location ==="
az group list --query "[?location=='$Location'].{Name:name,Location:location}" -o table

Write-Host ""