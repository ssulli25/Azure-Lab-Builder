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

### Hub Azure Firewall ###
data "azurerm_firewall" "hub" {
  count               = (var.HubEnabled && var.FwEnabled) ? 1 : 0
  provider            = azurerm.hub
  name                = "hub-${var.Region}-firewall"
  resource_group_name = "hub-network-${var.Region}-rg"
}

#========#
# Locals #
#========#

locals {
  ### App Gateway or Load balancer Locals ###
  backend_address_pool_name      = "${var.EnvName}-backend-pool"
  frontend_port_name             = "${var.EnvName}-fe-port"
  frontend_ip_configuration_name = "${var.EnvName}-fe-ip"
  http_setting_name              = "${var.EnvName}-be-htst"
  listener_name                  = "${var.EnvName}-http-lstn"
  request_routing_rule_name      = "${var.EnvName}-rq-rt"
  redirect_configuration_name    = "${var.EnvName}-rdr-cfg"
  health_probe_name              = "${var.EnvName}-health-probe"
  ### VMSS Backend Pool IDs ###
  app_gateway_backend_pool_ids = [for pool in toset(azurerm_application_gateway.web.backend_address_pool) : pool.id]
  ### Compute Images ###
  stripped_env_name        = replace(replace(var.EnvName, "sa-", ""), "hs-", "")
  web_vmss_source_image_id = "/subscriptions/${var.SubscriptionId}/resourceGroups/${local.stripped_env_name}-image-rg/providers/Microsoft.Compute/images/${var.WebImageId}"
  app_vmss_source_image_id = "/subscriptions/${var.SubscriptionId}/resourceGroups/${local.stripped_env_name}-image-rg/providers/Microsoft.Compute/images/${var.AppImageId}"
  data_vm_source_image_id  = "/subscriptions/${var.SubscriptionId}/resourceGroups/${local.stripped_env_name}-image-rg/providers/Microsoft.Compute/images/${var.DataImageId}"
}

#===============#
# Subscriptions #
#===============#

resource "azurerm_monitor_diagnostic_setting" "sub_diagnostic_settings" {
  name                       = "ActivityLog-to-${var.EnvName}-${var.Region}-law"
  target_resource_id         = data.azurerm_subscription.current.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "Administrative"
  }
  enabled_log {
    category = "Security"
  }
  enabled_log {
    category = "Alert"
  }
  enabled_log {
    category = "Policy"
  }
  enabled_log {
    category = "ResourceHealth"
  }
  enabled_log {
    category = "Autoscale"
  }
  enabled_log {
    category = "Recommendation"
  }
  enabled_log {
    category = "ServiceHealth"
  }
}

#================#
# Resource Group #
#================#

resource "azurerm_resource_group" "web_rg" {
  name     = "web-${var.EnvName}-rg"
  location = var.Region
}

resource "azurerm_resource_group" "app_rg" {
  name     = "app-${var.EnvName}-rg"
  location = var.Region
}

resource "azurerm_resource_group" "db_rg" {
  name     = "db-${var.EnvName}-rg"
  location = var.Region
}

resource "azurerm_resource_group" "network_rg" {
  name     = "network-${var.EnvName}-rg"
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

#============#
# Networking #
#============#

### Virtual Network and Subnets ###

resource "azurerm_virtual_network" "vnet" {
  name                = "spoke-${var.EnvName}-vnet"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
  address_space       = var.VnetAddressSpace
}

resource "azurerm_subnet" "appgw_subnet" {
  name                 = "appgw-subnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.AppGwSubnetPrefix
}

resource "azurerm_subnet" "web_subnet" {
  name                 = "web-subnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.WebSubnetPrefix
  default_outbound_access_enabled = false
}

resource "azurerm_subnet" "app_lb_subnet" {
  name                 = "app-lb-subnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.AppLbSubnetPrefix
}

resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.AppSubnetPrefix
  default_outbound_access_enabled = false
}

resource "azurerm_subnet" "data_lb_subnet" {
  name                 = "data-lb-subnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.DataLbSubnetPrefix
}

resource "azurerm_subnet" "data_subnet" {
  name                 = "data-subnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.DataSubnetPrefix
  default_outbound_access_enabled = false
}

### Peerings ###

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  count                        = var.HubEnabled ? 1 : 0
  provider                     = azurerm.hub
  name                         = "hub-to-spoke-${var.EnvName}"
  resource_group_name          = "hub-network-${var.Region}-rg"
  virtual_network_name         = data.azurerm_virtual_network.hub[0].name
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  count                        = var.HubEnabled ? 1 : 0
  name                         = "spoke-${var.EnvName}-to-hub"
  resource_group_name          = azurerm_resource_group.network_rg.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = data.azurerm_virtual_network.hub[0].id
  allow_virtual_network_access = true
}

### Web Application Gateway ###

resource "azurerm_application_gateway" "web" {
  name                = "web-${var.EnvName}-appgw"
  resource_group_name = azurerm_resource_group.web_rg.name
  location            = azurerm_resource_group.web_rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "ip-configuration-appgw"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.web_appgw.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}

### Web App Gateway Public IP Address ###

resource "azurerm_public_ip" "web_appgw" {
  name                = "web-${var.EnvName}-appgw-pip"
  location            = azurerm_resource_group.web_rg.location
  resource_group_name = azurerm_resource_group.web_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

### App Load Balancer ###

# Application Tier Internal Load Balancer
resource "azurerm_lb" "app_lb" {
  name                = "app-${var.EnvName}-lb"
  resource_group_name = azurerm_resource_group.app_rg.name
  location            = azurerm_resource_group.app_rg.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = local.frontend_ip_configuration_name
    subnet_id                     = azurerm_subnet.app_lb_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "app_backend_pool" {
  loadbalancer_id = azurerm_lb.app_lb.id
  name            = local.backend_address_pool_name
}

resource "azurerm_lb_probe" "app_probe" {
  loadbalancer_id     = azurerm_lb.app_lb.id
  name                = local.health_probe_name
  protocol            = "Http"
  port                = 80
  request_path        = "/"
  interval_in_seconds = 15
}

resource "azurerm_lb_rule" "app_rule" {
  loadbalancer_id                = azurerm_lb.app_lb.id
  name                           = "app-${var.EnvName}-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = local.frontend_ip_configuration_name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.app_backend_pool.id]
  probe_id                       = azurerm_lb_probe.app_probe.id
}

### Data Load Balancer ###

# Database Tier Internal Load Balancer
resource "azurerm_lb" "data_lb" {
  name                = "db-${var.EnvName}-lb"
  resource_group_name = azurerm_resource_group.db_rg.name
  location            = azurerm_resource_group.db_rg.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = local.frontend_ip_configuration_name
    subnet_id                     = azurerm_subnet.data_lb_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "data_backend_pool" {
  loadbalancer_id = azurerm_lb.data_lb.id
  name            = local.backend_address_pool_name
}

resource "azurerm_lb_probe" "data_probe" {
  loadbalancer_id = azurerm_lb.data_lb.id
  name            = local.health_probe_name
  protocol        = "Tcp"
  port            = 1433
}

resource "azurerm_lb_rule" "data_rule" {
  loadbalancer_id                = azurerm_lb.data_lb.id
  name                           = "db-${var.EnvName}-lb-rule"
  protocol                       = "Tcp"
  frontend_port                  = 1433
  backend_port                   = 1433
  frontend_ip_configuration_name = local.frontend_ip_configuration_name
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.data_backend_pool.id]
  probe_id                       = azurerm_lb_probe.data_probe.id
}

### Network Security Groups ###

resource "azurerm_network_security_group" "web_nsg" {
  name                = "web-${var.EnvName}-nsg"
  resource_group_name = azurerm_resource_group.web_rg.name
  location            = azurerm_resource_group.web_rg.location

  dynamic "security_rule" {
    for_each = var.HubEnabled ? [1] : []
    content {
      name                       = "Allow-ICMP-Hub-Mgmt-Tier"
      priority                   = 125
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Icmp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = data.azurerm_subnet.mgmt[0].address_prefix
      destination_address_prefix = var.WebSubnetPrefix[0]
    }
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = var.WebSubnetPrefix[0]
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = var.WebSubnetPrefix[0]
  }

  security_rule {
    name                       = "Allow-Health-Probe"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = var.WebSubnetPrefix[0]
  }

  security_rule {
    name                       = "Allow-ICMP-App-Tier"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.AppSubnetPrefix[0]
    destination_address_prefix = var.WebSubnetPrefix[0]
  }

  security_rule {
    name                       = "Allow-Bastion-SSH"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = var.WebSubnetPrefix[0]
  }

    security_rule {
    name                       = "Allow-Bastion-RDP"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = var.WebSubnetPrefix[0]
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = var.WebSubnetPrefix[0]
  }
}

resource "azurerm_network_security_group" "app_nsg" {
  name                = "app-${var.EnvName}-nsg"
  resource_group_name = azurerm_resource_group.app_rg.name
  location            = azurerm_resource_group.app_rg.location

  dynamic "security_rule" {
    for_each = var.HubEnabled ? [1] : []
    content {
      name                       = "Allow-ICMP-Hub-Mgmt-Tier"
      priority                   = 125
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Icmp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = data.azurerm_subnet.mgmt[0].address_prefix
      destination_address_prefix = var.AppSubnetPrefix[0]
    }
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.WebSubnetPrefix[0]
    destination_address_prefix = var.AppSubnetPrefix[0]
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.WebSubnetPrefix[0]
    destination_address_prefix = var.AppSubnetPrefix[0]
  }

  security_rule {
    name                       = "Allow-Health-Probe"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = var.AppSubnetPrefix[0]
  }

  security_rule {
    name                       = "Allow-ICMP-Web-Data-Tiers"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = [var.WebSubnetPrefix[0], var.DataSubnetPrefix[0]]
    destination_address_prefix = var.AppSubnetPrefix[0]
  }

  security_rule {
    name                       = "Allow-Bastion-SSH"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = var.AppSubnetPrefix[0]
  }

    security_rule {
    name                       = "Allow-Bastion-RDP"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = var.AppSubnetPrefix[0]
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = var.AppSubnetPrefix[0]
  }

}

resource "azurerm_network_security_group" "data_nsg" {
  name                = "db-${var.EnvName}-nsg"
  resource_group_name = azurerm_resource_group.db_rg.name
  location            = azurerm_resource_group.db_rg.location

  dynamic "security_rule" {
    for_each = var.HubEnabled ? [1] : []
    content {
      name                       = "Allow-ICMP-Hub-Mgmt-Tier"
      priority                   = 125
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Icmp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = data.azurerm_subnet.mgmt[0].address_prefix
      destination_address_prefix = var.DataSubnetPrefix[0]
    }
  }

  security_rule {
    name                       = "Allow-DB-Traffic"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = var.AppSubnetPrefix[0]
    destination_address_prefix = var.DataSubnetPrefix[0]
  }

  security_rule {
    name                       = "Allow-Health-Probe"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = var.DataSubnetPrefix[0]
  }

  security_rule {
    name                       = "Allow-ICMP-App-Tier"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.AppSubnetPrefix[0]
    destination_address_prefix = var.DataSubnetPrefix[0]
  }

    security_rule {
    name                       = "Allow-Bastion-SSH"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = var.DataSubnetPrefix[0]
  }

    security_rule {
    name                       = "Allow-Bastion-RDP"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = var.DataSubnetPrefix[0]
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = var.DataSubnetPrefix[0]
  }
}

resource "azurerm_subnet_network_security_group_association" "web_nsg_association" {
  subnet_id                 = azurerm_subnet.web_subnet.id
  network_security_group_id = azurerm_network_security_group.web_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "app_nsg_association" {
  subnet_id                 = azurerm_subnet.app_subnet.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "data_nsg_association" {
  subnet_id                 = azurerm_subnet.data_subnet.id
  network_security_group_id = azurerm_network_security_group.data_nsg.id
}

### Route Tables Spoke ###

resource "azurerm_route_table" "fw_route_table" {
  count               = (var.HubEnabled && var.FwEnabled) ? 1 : 0
  name                = "spoke-firewall-route-table"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location

  route {
    name                   = "default-route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = data.azurerm_firewall.hub[0].ip_configuration[0].private_ip_address
  }
  route {
    name           = "local-route"
    address_prefix = tolist(azurerm_virtual_network.vnet.address_space)[0]
    next_hop_type  = "VnetLocal"
  }
}

resource "azurerm_route_table" "appgw_route_table" {
  count               = var.FwEnabled ? 1 : 0
  name                = "spoke-appgw-route-table"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location

  route {
    name           = "default-route"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
  route {
    name           = "local-route"
    address_prefix = tolist(azurerm_virtual_network.vnet.address_space)[0]
    next_hop_type  = "VnetLocal"
  }
}

resource "azurerm_subnet_route_table_association" "web_route_table_association" {
  count          = (var.HubEnabled && var.FwEnabled) ? 1 : 0
  subnet_id      = azurerm_subnet.web_subnet.id
  route_table_id = azurerm_route_table.fw_route_table[0].id
}

resource "azurerm_subnet_route_table_association" "appgw_route_table_association" {
  count          = (var.HubEnabled && var.FwEnabled) ? 1 : 0
  subnet_id      = azurerm_subnet.appgw_subnet.id
  route_table_id = azurerm_route_table.appgw_route_table[0].id
}

resource "azurerm_subnet_route_table_association" "app_route_table_association" {
  count          = (var.HubEnabled && var.FwEnabled) ? 1 : 0
  subnet_id      = azurerm_subnet.app_subnet.id
  route_table_id = azurerm_route_table.fw_route_table[0].id
}

resource "azurerm_subnet_route_table_association" "applb_route_table_association" {
  count          = (var.HubEnabled && var.FwEnabled) ? 1 : 0
  subnet_id      = azurerm_subnet.app_lb_subnet.id
  route_table_id = azurerm_route_table.fw_route_table[0].id
}

resource "azurerm_subnet_route_table_association" "data_route_table_association" {
  count          = (var.HubEnabled && var.FwEnabled) ? 1 : 0
  subnet_id      = azurerm_subnet.data_subnet.id
  route_table_id = azurerm_route_table.fw_route_table[0].id
}

resource "azurerm_subnet_route_table_association" "datalb_route_table_association" {
  count          = (var.HubEnabled && var.FwEnabled) ? 1 : 0
  subnet_id      = azurerm_subnet.data_lb_subnet.id
  route_table_id = azurerm_route_table.fw_route_table[0].id
}

#=========#
# Compute #
#=========#

### Web Virtual Machine Scale Set ###

resource "azurerm_linux_virtual_machine_scale_set" "web_vmss" {
  name                            = "web-${var.EnvName}-vmss"
  resource_group_name             = azurerm_resource_group.web_rg.name
  location                        = azurerm_resource_group.web_rg.location
  sku                             = var.WebVmssSize
  instances                       = var.WebInstanceCount
  admin_username                  = var.AdminUsername
  admin_password                  = var.AdminPassword
  disable_password_authentication = false

  network_interface {
    name    = "nic-web-${var.EnvName}-vmss"
    primary = true

    ip_configuration {
      name                                         = "internal"
      primary                                      = true
      subnet_id                                    = azurerm_subnet.web_subnet.id
      application_gateway_backend_address_pool_ids = [local.app_gateway_backend_pool_ids[0]]
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_id = local.web_vmss_source_image_id
}

### Application Virtual Machine Scale Set ###

resource "azurerm_linux_virtual_machine_scale_set" "app_vmss" {
  name                            = "app-${var.EnvName}-vmss"
  resource_group_name             = azurerm_resource_group.app_rg.name
  location                        = azurerm_resource_group.app_rg.location
  sku                             = var.AppVmssSize
  instances                       = var.AppInstanceCount
  admin_username                  = var.AdminUsername
  admin_password                  = var.AdminPassword
  disable_password_authentication = false

  network_interface {
    name    = "nic-app-${var.EnvName}-vmss"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.app_subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.app_backend_pool.id]
    }
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_id = local.app_vmss_source_image_id
}

### Database Virtual Machines ###

resource "azurerm_linux_virtual_machine" "db_vm_primary" {
  name                            = "db-${var.EnvName}-vm-primary"
  resource_group_name             = azurerm_resource_group.db_rg.name
  location                        = azurerm_resource_group.db_rg.location
  size                            = var.DbVmSize
  admin_username                  = var.AdminUsername
  admin_password                  = var.AdminPassword
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.db_nic_primary.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_id = local.data_vm_source_image_id
}

resource "azurerm_network_interface" "db_nic_primary" {
  name                = "nic-db-${var.EnvName}-vm-primary"
  resource_group_name = azurerm_resource_group.db_rg.name
  location            = azurerm_resource_group.db_rg.location

  ip_configuration {
    name                          = "nic-db-${var.EnvName}-vm-config"
    subnet_id                     = azurerm_subnet.data_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "primary_association" {
  network_interface_id    = azurerm_network_interface.db_nic_primary.id
  ip_configuration_name   = "nic-db-${var.EnvName}-vm-config"
  backend_address_pool_id = azurerm_lb_backend_address_pool.data_backend_pool.id
}

resource "azurerm_linux_virtual_machine" "db_vm_secondary" {
  name                            = "db-${var.EnvName}-vm-secondary"
  resource_group_name             = azurerm_resource_group.db_rg.name
  location                        = azurerm_resource_group.db_rg.location
  size                            = var.DbVmSize
  admin_username                  = var.AdminUsername
  admin_password                  = var.AdminPassword
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.db_nic_secondary.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_id = local.data_vm_source_image_id
}

resource "azurerm_network_interface" "db_nic_secondary" {
  name                = "nic-db-${var.EnvName}-vm-secondary"
  resource_group_name = azurerm_resource_group.db_rg.name
  location            = azurerm_resource_group.db_rg.location

  ip_configuration {
    name                          = "nic-db-${var.EnvName}-vm-config"
    subnet_id                     = azurerm_subnet.data_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "secondary_association" {
  network_interface_id    = azurerm_network_interface.db_nic_secondary.id
  ip_configuration_name   = "nic-db-${var.EnvName}-vm-config"
  backend_address_pool_id = azurerm_lb_backend_address_pool.data_backend_pool.id
}

### Database Data Disks ###

resource "azurerm_managed_disk" "primary_data_disk" {
  name                 = "db-${var.EnvName}-vm-primary-data-disk"
  resource_group_name  = azurerm_resource_group.db_rg.name
  location             = azurerm_resource_group.db_rg.location
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 64
}

resource "azurerm_virtual_machine_data_disk_attachment" "primary_data_disk_attachment" {
  managed_disk_id    = azurerm_managed_disk.primary_data_disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.db_vm_primary.id
  lun                = 0
  caching            = "ReadWrite"
}

resource "azurerm_managed_disk" "secondary_data_disk" {
  name                 = "db-${var.EnvName}-vm-secondary-data-disk"
  resource_group_name  = azurerm_resource_group.db_rg.name
  location             = azurerm_resource_group.db_rg.location
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 64
}

resource "azurerm_virtual_machine_data_disk_attachment" "secondary_data_disk_attachment" {
  managed_disk_id    = azurerm_managed_disk.secondary_data_disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.db_vm_secondary.id
  lun                = 0
  caching            = "ReadWrite"
}
