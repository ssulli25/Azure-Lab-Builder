param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId
)

az account set --subscription $SubscriptionId

Write-Host "=== Azure Subscription Cost Estimation ==="
$subCosts = az consumption usage list --subscription $SubscriptionId --query "[].{Resource:instanceName, Cost:pretaxCost, Service:productName, ResourceGroup:resourceGroup}" -o table
Write-Output $subCosts

Write-Host "`n=== Azure Resource Group Cost Estimation ==="
$resourceGroups = az group list --query "[].name" -o tsv
foreach ($rg in $resourceGroups) {
    Write-Host "`nResource Group: $rg"
    $rgCosts = az consumption usage list --subscription $SubscriptionId --resource-group $rg --query "[].{Resource:instanceName, Cost:pretaxCost, Service:productName}" -o table
    Write-Output $rgCosts
}