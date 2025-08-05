param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    [Parameter(Mandatory=$true)]
    [string]$Location
)

az account set --subscription $SubscriptionId

Write-Host "=== VM Quota Usage ==="
az vm list-usage --location $Location -o table

Write-Host "`n=== Storage Quota Usage ==="
az storage account show-usage --location $Location -o table

Write-Host "`n=== Resource Groups in Location ==="
az group list --query "[?location=='$Location'].{Name:name,Location:location}" -o table