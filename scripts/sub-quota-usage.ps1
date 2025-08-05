param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    [Parameter(Mandatory=$true)]
    [string]$Location
)

az account set --subscription $SubscriptionId

Write-Host "=== VM Quota Usage ==="
az vm list-usage --location $Location

Write-Host "`n=== VMSS Quota Usage ==="
az vmss list-skus --location $Location

Write-Host "`n=== Storage Account Quota Usage ==="
az storage account list-usage --location $Location

Write-Host "`n=== Managed Disk Quota Usage ==="
az disk list-usage --location $Location

Write-Host "`n=== Virtual Network Quota Usage ==="
az network vnet list-usage --location $Location

Write-Host "`n=== Subnet Quota Usage ==="
az network vnet subnet list-usage --location $Location

Write-Host "`n=== Public IP Quota Usage ==="
az network public-ip list-usage --location $Location

Write-Host "`n=== Load Balancer Quota Usage ==="
az network lb list-usage --location $Location

Write-Host "`n=== NAT Gateway Quota Usage ==="
az network nat gateway list-usage --location $Location

Write-Host "`n=== Application Gateway Quota Usage ==="
az network application-gateway list-usage --location $Location

Write-Host "`n=== ExpressRoute Quota Usage ==="
az network express-route list-usage --location $Location

Write-Host "`n=== Virtual Network Gateway Quota Usage ==="
az network vnet-gateway list-usage --location $Location

Write-Host "`n=== Bastion Host Quota Usage ==="
az network bastion list-usage --location $Location

Write-Host "`n=== Firewall Quota Usage ==="
az network firewall list-usage --location $Location

Write-Host "`n=== DDoS Protection Plan Quota Usage ==="
az network ddos-protection list-usage --location $Location

Write-Host "`n=== Route Table Quota Usage ==="
az network route-table list-usage --location $Location

Write-Host "`n=== Log Analytics Workspace Quota Usage ==="
az monitor log-analytics workspace list-usage --location $Location

Write-Host "`n=== Resource Group Quota Usage ==="
az group list --query "[?location=='$Location']" -o table