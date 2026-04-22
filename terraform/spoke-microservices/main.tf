#======#
# Data #
#======#

### Spoke Subscription ###
data "azurerm_subscription" "current" {
}

### Hub Virtual Network ###
data "azurerm_virtual_network" "hub" {
  count               = var.HubEnabled ? 1 : 0
  provider            = azurerm.hub
  name                = "hub-${var.Region}-vnet"
  resource_group_name = "hub-network-${var.Region}-rg"
}

### Hub Management Subnet ###
data "azurerm_subnet" "mgmt" {
  count                = var.HubEnabled ? 1 : 0
  provider             = azurerm.hub
  name                 = "mgmt-subnet"
  virtual_network_name = data.azurerm_virtual_network.hub[0].name
  resource_group_name  = data.azurerm_virtual_network.hub[0].resource_group_name
}

### Virtual Network Gateway Subnet ###
data "azurerm_subnet" "gateway" {
  count                = var.HubEnabled ? 1 : 0
  provider             = azurerm.hub
  name                 = "GatewaySubnet"
  virtual_network_name = data.azurerm_virtual_network.hub[0].name
  resource_group_name  = data.azurerm_virtual_network.hub[0].resource_group_name
}

### Hub Azure Firewall ###
data "azurerm_firewall" "hub" {
  count               = (var.HubEnabled && var.FwEnabled) ? 1 : 0
  provider            = azurerm.hub
  name                = "hub-${var.Region}-firewall"
  resource_group_name = "hub-network-${var.Region}-rg"
}

#================#
# Resource Group #
#================#

resource "azurerm_resource_group" "network_rg" {
  name     = "network-${var.EnvName}-rg"
  location = var.Region
}

resource "azurerm_resource_group" "aks_rg" {
  name     = "aks-${var.EnvName}-rg"
  location = var.Region
}

resource "azurerm_resource_group" "data_rg" {
  name     = "data-${var.EnvName}-rg"
  location = var.Region
}

resource "azurerm_resource_group" "platform_rg" {
  name     = "platform-${var.EnvName}-rg"
  location = var.Region
}

resource "azurerm_resource_group" "monitor_rg" {
  name     = "monitor-${var.EnvName}-rg"
  location = var.Region
}

#============#
# Monitoring #
#============#

resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.EnvName}-${var.Region}-law"
  resource_group_name = azurerm_resource_group.monitor_rg.name
  location            = azurerm_resource_group.monitor_rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "sub_diagnostic_settings" {
  name                       = "ActivityLog-to-${var.EnvName}-${var.Region}-law"
  target_resource_id         = data.azurerm_subscription.current.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log { category = "Administrative" }
  enabled_log { category = "Security" }
  enabled_log { category = "Alert" }
  enabled_log { category = "Policy" }
  enabled_log { category = "ResourceHealth" }
  enabled_log { category = "Autoscale" }
  enabled_log { category = "Recommendation" }
  enabled_log { category = "ServiceHealth" }
}

#============#
# Networking #
#============#

resource "azurerm_virtual_network" "vnet" {
  name                = "spoke-${var.EnvName}-vnet"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
  address_space       = var.VnetAddressSpace
}

resource "azurerm_subnet" "aks_system_subnet" {
  name                 = "aks-system-subnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.AksSystemSubnetPrefix
}

resource "azurerm_subnet" "aks_user_subnet" {
  name                 = "aks-user-subnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.AksUserSubnetPrefix
}

resource "azurerm_subnet" "appgw_subnet" {
  name                 = "appgw-subnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.AppGwSubnetPrefix
}

resource "azurerm_subnet" "pe_subnet" {
  name                              = "pe-subnet"
  resource_group_name               = azurerm_resource_group.network_rg.name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = var.PrivateEndpointSubnetPrefix
  private_endpoint_network_policies = "Enabled"
}

### VNet Peering ###

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  count                        = var.HubEnabled ? 1 : 0
  provider                     = azurerm.hub
  name                         = "hub-to-spoke-${var.EnvName}"
  resource_group_name          = "hub-network-${var.Region}-rg"
  virtual_network_name         = data.azurerm_virtual_network.hub[0].name
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  count                        = var.HubEnabled ? 1 : 0
  name                         = "spoke-${var.EnvName}-to-hub"
  resource_group_name          = azurerm_resource_group.network_rg.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = data.azurerm_virtual_network.hub[0].id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

### NSGs ###

resource "azurerm_network_security_group" "aks_nsg" {
  name                = "aks-${var.EnvName}-nsg"
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name
}

resource "azurerm_subnet_network_security_group_association" "aks_system_nsg_assoc" {
  subnet_id                 = azurerm_subnet.aks_system_subnet.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "aks_user_nsg_assoc" {
  subnet_id                 = azurerm_subnet.aks_user_subnet.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

resource "azurerm_network_security_group" "appgw_nsg" {
  name                = "appgw-${var.EnvName}-nsg"
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name

  # App Gateway v2 control-plane requirement
  security_rule {
    name                       = "Allow-GatewayManager"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow-AzureLoadBalancer"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow-Internet-HTTPS"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow-Internet-HTTP"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "appgw_nsg_assoc" {
  subnet_id                 = azurerm_subnet.appgw_subnet.id
  network_security_group_id = azurerm_network_security_group.appgw_nsg.id
}

### Egress: Route Table to hub firewall when present, otherwise NAT Gateway ###

resource "azurerm_route_table" "rt_to_firewall" {
  count                         = (var.HubEnabled && var.FwEnabled) ? 1 : 0
  name                          = "${var.EnvName}-fw-rt"
  location                      = azurerm_resource_group.network_rg.location
  resource_group_name           = azurerm_resource_group.network_rg.name
  bgp_route_propagation_enabled = false

  route {
    name                   = "default-firewall-route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = data.azurerm_firewall.hub[0].ip_configuration[0].private_ip_address
  }
  route {
    name                   = "mgmt-firewall-route"
    address_prefix         = data.azurerm_subnet.mgmt[0].address_prefixes[0]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = data.azurerm_firewall.hub[0].ip_configuration[0].private_ip_address
  }
  route {
    name                   = "gateway-firewall-route"
    address_prefix         = data.azurerm_subnet.gateway[0].address_prefixes[0]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = data.azurerm_firewall.hub[0].ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "aks_system_rt_assoc" {
  count          = (var.HubEnabled && var.FwEnabled) ? 1 : 0
  subnet_id      = azurerm_subnet.aks_system_subnet.id
  route_table_id = azurerm_route_table.rt_to_firewall[0].id
}

resource "azurerm_subnet_route_table_association" "aks_user_rt_assoc" {
  count          = (var.HubEnabled && var.FwEnabled) ? 1 : 0
  subnet_id      = azurerm_subnet.aks_user_subnet.id
  route_table_id = azurerm_route_table.rt_to_firewall[0].id
}

### NAT Gateway used when hub firewall is not providing egress ###

resource "azurerm_public_ip" "nat_gateway_pip" {
  count               = (var.HubEnabled && var.FwEnabled) ? 0 : 1
  name                = "${var.EnvName}-nat-pip"
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat_gateway" {
  count               = (var.HubEnabled && var.FwEnabled) ? 0 : 1
  name                = "${var.EnvName}-nat-gateway"
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gateway_pip_assoc" {
  count                = (var.HubEnabled && var.FwEnabled) ? 0 : 1
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway[0].id
  public_ip_address_id = azurerm_public_ip.nat_gateway_pip[0].id
}

resource "azurerm_subnet_nat_gateway_association" "aks_system_nat_assoc" {
  count          = (var.HubEnabled && var.FwEnabled) ? 0 : 1
  subnet_id      = azurerm_subnet.aks_system_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway[0].id
}

resource "azurerm_subnet_nat_gateway_association" "aks_user_nat_assoc" {
  count          = (var.HubEnabled && var.FwEnabled) ? 0 : 1
  subnet_id      = azurerm_subnet.aks_user_subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway[0].id
}

#====================#
# Workload Identity  #
#====================#

resource "azurerm_user_assigned_identity" "workload" {
  name                = "${var.EnvName}-workload-uai"
  location            = azurerm_resource_group.platform_rg.location
  resource_group_name = azurerm_resource_group.platform_rg.name
}

#==========================#
# Azure Container Registry #
#==========================#

resource "azurerm_container_registry" "acr" {
  # ACR name must be globally unique, alphanumeric, lowercase
  name                          = lower(replace("acr${var.EnvName}${var.Region}", "/[^a-z0-9]/", ""))
  resource_group_name           = azurerm_resource_group.platform_rg.name
  location                      = azurerm_resource_group.platform_rg.location
  sku                           = var.AcrSku
  admin_enabled                 = false
  public_network_access_enabled = false
}

resource "azurerm_private_endpoint" "acr_pe" {
  name                = "${var.EnvName}-acr-pe"
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name
  subnet_id           = azurerm_subnet.pe_subnet.id

  private_service_connection {
    name                           = "${var.EnvName}-acr-psc"
    private_connection_resource_id = azurerm_container_registry.acr.id
    is_manual_connection           = false
    subresource_names              = ["registry"]
  }

  private_dns_zone_group {
    name                 = "acr-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }
}

#=============#
# Azure SQL   #
#=============#

resource "azurerm_mssql_server" "sql" {
  # SQL server name must be globally unique, lowercase
  name                          = lower("${var.EnvName}-${var.Region}-sql")
  resource_group_name           = azurerm_resource_group.data_rg.name
  location                      = azurerm_resource_group.data_rg.location
  version                       = "12.0"
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false

  administrator_login          = var.SqlAdminLogin
  administrator_login_password = var.AdminPassword
}

resource "azurerm_mssql_database" "app_db" {
  name           = "appdb"
  server_id      = azurerm_mssql_server.sql.id
  sku_name       = var.SqlDatabaseSku
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  zone_redundant = false

  # Serverless-only settings (GP_S_*). min_capacity must be >= 0.5; 0 is rejected.
  min_capacity                = startswith(var.SqlDatabaseSku, "GP_S_") ? 1 : null
  auto_pause_delay_in_minutes = startswith(var.SqlDatabaseSku, "GP_S_") ? 60 : null
}

resource "azurerm_private_endpoint" "sql_pe" {
  name                = "${var.EnvName}-sql-pe"
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name
  subnet_id           = azurerm_subnet.pe_subnet.id

  private_service_connection {
    name                           = "${var.EnvName}-sql-psc"
    private_connection_resource_id = azurerm_mssql_server.sql.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "sql-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }
}

#=============#
# Key Vault   #
#=============#

resource "azurerm_key_vault" "kv" {
  # KV name must be globally unique, 3-24 chars, alphanumeric/hyphens
  name                          = substr(lower(replace("kv-${var.EnvName}-${var.Region}", "/[^a-z0-9-]/", "")), 0, 24)
  resource_group_name           = azurerm_resource_group.platform_rg.name
  location                      = azurerm_resource_group.platform_rg.location
  tenant_id                     = data.azurerm_subscription.current.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true
  public_network_access_enabled = false
  purge_protection_enabled      = false
  soft_delete_retention_days    = 7
}

resource "azurerm_private_endpoint" "kv_pe" {
  name                = "${var.EnvName}-kv-pe"
  location            = azurerm_resource_group.network_rg.location
  resource_group_name = azurerm_resource_group.network_rg.name
  subnet_id           = azurerm_subnet.pe_subnet.id

  private_service_connection {
    name                           = "${var.EnvName}-kv-psc"
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "kv-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv.id]
  }
}

#====================#
# Private DNS Zones  #
#====================#

resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.network_rg.name
}

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.network_rg.name
}

resource "azurerm_private_dns_zone" "kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.network_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_link" {
  name                  = "acr-link-${var.EnvName}"
  resource_group_name   = azurerm_resource_group.network_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_link" {
  name                  = "sql-link-${var.EnvName}"
  resource_group_name   = azurerm_resource_group.network_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv_link" {
  name                  = "kv-link-${var.EnvName}"
  resource_group_name   = azurerm_resource_group.network_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.kv.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

#=====#
# AKS #
#=====#

resource "azurerm_kubernetes_cluster" "aks" {
  name                      = "${var.EnvName}-${var.Region}-aks"
  location                  = azurerm_resource_group.aks_rg.location
  resource_group_name       = azurerm_resource_group.aks_rg.name
  dns_prefix                = "${var.EnvName}-${var.Region}"
  kubernetes_version        = var.AksKubernetesVersion
  private_cluster_enabled   = true
  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  azure_policy_enabled      = true
  local_account_disabled    = true
  sku_tier                  = "Standard"
  node_resource_group       = "aks-nodes-${var.EnvName}-rg"

  default_node_pool {
    name                         = "system"
    vm_size                      = var.AksSystemNodeVmSize
    vnet_subnet_id               = azurerm_subnet.aks_system_subnet.id
    node_count                   = 1
    only_critical_addons_enabled = true
    # orchestrator_version omitted to inherit kubernetes_version from the cluster
    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_subscription.current.tenant_id
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "calico"
    pod_cidr            = var.AksPodCidr
    service_cidr        = var.AksServiceCidr
    dns_service_ip      = var.AksDnsServiceIp
    load_balancer_sku   = "standard"
    outbound_type       = (var.HubEnabled && var.FwEnabled) ? "userDefinedRouting" : "userAssignedNATGateway"
  }

  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.law.id
    msi_auth_for_monitoring_enabled = true
  }

  microsoft_defender {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  }

  ingress_application_gateway {
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  depends_on = [
    azurerm_subnet_route_table_association.aks_system_rt_assoc,
    azurerm_subnet_nat_gateway_association.aks_system_nat_assoc,
  ]
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.AksUserNodeVmSize
  vnet_subnet_id        = azurerm_subnet.aks_user_subnet.id
  auto_scaling_enabled  = true
  min_count             = var.AksUserNodeMin
  max_count             = var.AksUserNodeMax
  mode                  = "User"
  # orchestrator_version omitted to inherit kubernetes_version from the cluster

  upgrade_settings {
    max_surge = "33%"
  }

  depends_on = [
    azurerm_subnet_route_table_association.aks_user_rt_assoc,
    azurerm_subnet_nat_gateway_association.aks_user_nat_assoc,
  ]
}

#====================#
# Role Assignments   #
#====================#

# AKS kubelet identity needs AcrPull on ACR to pull images
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# Workload identity needs Key Vault Secrets User on the KV
resource "azurerm_role_assignment" "workload_kv_secrets" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}

#======================#
# Diagnostic Settings  #
#======================#

resource "azurerm_monitor_diagnostic_setting" "aks_diag" {
  name                       = "aks-to-${var.EnvName}-${var.Region}-law"
  target_resource_id         = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log { category = "kube-apiserver" }
  enabled_log { category = "kube-controller-manager" }
  enabled_log { category = "kube-scheduler" }
  enabled_log { category = "kube-audit-admin" }
  enabled_log { category = "guard" }

  enabled_metric { category = "AllMetrics" }
}

resource "azurerm_monitor_diagnostic_setting" "sql_diag" {
  name                       = "sql-to-${var.EnvName}-${var.Region}-law"
  target_resource_id         = azurerm_mssql_database.app_db.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log { category = "SQLSecurityAuditEvents" }
  enabled_log { category = "Errors" }
  enabled_log { category = "QueryStoreRuntimeStatistics" }

  enabled_metric { category = "AllMetrics" }
}

resource "azurerm_monitor_diagnostic_setting" "acr_diag" {
  name                       = "acr-to-${var.EnvName}-${var.Region}-law"
  target_resource_id         = azurerm_container_registry.acr.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log { category = "ContainerRegistryRepositoryEvents" }
  enabled_log { category = "ContainerRegistryLoginEvents" }

  enabled_metric { category = "AllMetrics" }
}

resource "azurerm_monitor_diagnostic_setting" "kv_diag" {
  name                       = "kv-to-${var.EnvName}-${var.Region}-law"
  target_resource_id         = azurerm_key_vault.kv.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log { category = "AuditEvent" }
  enabled_log { category = "AzurePolicyEvaluationDetails" }

  enabled_metric { category = "AllMetrics" }
}
