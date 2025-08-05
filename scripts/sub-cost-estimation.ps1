param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId
)

az account set --subscription $SubscriptionId

Write-Host "=== Azure Subscription Cost Estimation ==="
az consumption usage list --subscription $SubscriptionId --query "[].{Resource:instanceName, Cost:pretaxCost, Service:productName}" -o table