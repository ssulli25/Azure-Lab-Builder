#======#
# Data #
#======#

### Hub Subscription ###
data "azurerm_subscription" "current" {
}

#========#
# Locals #
#========#

locals {
  subnet_ids = { for subnet in azurerm_virtual_network.vnet.subnet : subnet.name => subnet.id }
}

#===============#
# Subscriptions #
#===============#

resource "azurerm_monitor_diagnostic_setting" "sub_diagnostic_settings" {
  name                       = "ActivityLog-to-hub-law-${var.Region}"
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

resource "azurerm_resource_group" "network_rg" {
  name     = "hub-network-${var.Region}-rg"
  location = var.Region
}

resource "azurerm_resource_group" "monitor_rg" {
  name     = "hub-monitor-${var.Region}-rg"
  location = var.Region
}

#============#
# Networking #
#============#

### Virtual Network and Subnets ###

resource "azurerm_virtual_network" "vnet" {
  name                = "hub-vnet-${var.Region}"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
  address_space       = var.VnetAddressSpace
}

resource "azurerm_subnet" "mgmt" {
  name                 = "mgmt-subnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.MgmtSubnetPrefix
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.GatewaySubnetPrefix
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.BastionSubnetPrefix
}

resource "azurerm_subnet" "az_firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.AzFirewallSubnetPrefix
}

resource "azurerm_subnet" "az_mgmt_firewall" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.AzFirewallMgmtSubnetPrefix
}

### Virtual Network Gateway ###

resource "azurerm_virtual_network_gateway" "vng_gateway" {
  name                = "hub-vng-${var.Region}"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
  type                = var.VngType
  vpn_type            = var.VngVpnType
  sku                 = var.VngSku

  ip_configuration {
    name                 = "hub-vng-${var.Region}-ipconfig"
    subnet_id            = azurerm_subnet.gateway.id
    public_ip_address_id = azurerm_public_ip.vng_pip.id
  }
}

resource "azurerm_public_ip" "vng_pip" {
  name                = "hub-vng-${var.Region}-pip"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

### Bastion Host ###

resource "azurerm_bastion_host" "bastion" {
  count               = var.BastionEnabled ? 1 : 0
  name                = "hub-bastion-${var.Region}"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location

  ip_configuration {
    name                 = "hub-bastion-${var.Region}-ipconfig"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }
}

resource "azurerm_public_ip" "bastion" {
  count               = var.BastionEnabled ? 1 : 0
  name                = "hub-bastion-${var.Region}-pip"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

### Route Tables Hub ###

resource "azurerm_route_table" "fw_route_table" {
  count               = var.FwEnabled ? 1 : 0
  name                = "hub-route-table-firewall"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location

  route {
    name                   = "default-route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }
  route {
    name           = "local-route"
    address_prefix = azurerm_virtual_network.vnet.address_space
    next_hop_type  = "VnetLocal"
  }
}

resource "azurerm_subnet_route_table_association" "fw_route_table_association" {
  for_each       = local.subnet_ids
  subnet_id      = each.value
  route_table_id = azurerm_route_table.fw_route_table.id
}

#============#
# Monitoring #
#============#

resource "azurerm_log_analytics_workspace" "law" {
  name                = "hub-law-${var.Region}"
  resource_group_name = azurerm_resource_group.monitor_rg.name
  location            = azurerm_resource_group.monitor_rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

#==========#
# Security #
#==========#

### Firewall ###

resource "azurerm_firewall" "firewall" {
  count               = var.FwEnabled ? 1 : 0
  name                = "hub-firewall-${var.Region}"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location

  sku_name = "AZFW_VNet"
  sku_tier = var.AzFwTier

  firewall_policy_id = azurerm_firewall_policy.firewall_policy[0].id

  ip_configuration {
    name      = "hub-firewall-${var.Region}-ip-config"
    subnet_id = azurerm_subnet.az_firewall.id
  }

  management_ip_configuration {
    name                 = "hub-firewall-${var.Region}-mgmt-config"
    subnet_id            = azurerm_subnet.az_mgmt_firewall.id
    public_ip_address_id = azurerm_public_ip.firewall_pip[0].id
  }

}

resource "azurerm_public_ip" "firewall_pip" {
  count               = var.FwEnabled ? 1 : 0
  name                = "hub-firewall-${var.Region}-pip"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall_policy" "firewall_policy" {
  count               = var.FwEnabled ? 1 : 0
  name                = "hub-firewall-${var.Region}-policy-primary"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
}

resource "azurerm_firewall_policy_rule_collection_group" "collection_group_policy" {
  count              = var.FwEnabled ? 1 : 0
  name               = "DefaultNetworkRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.firewall_policy[0].id
  priority           = 200

  network_rule_collection {
    name     = "network-rule-collection-primary"
    priority = 1000
    action   = "Allow"
    rule {
      name                  = "https-rule"
      source_addresses      = ["*"]
      destination_ports     = ["443"]
      protocols             = ["TCP"]
      destination_addresses = ["*"]
    }
    rule {
      name                  = "dns-rule"
      source_addresses      = ["*"]
      destination_ports     = ["53"]
      protocols             = ["TCP", "UDP"]
      destination_addresses = ["*"]
    }
    rule {
      name                  = "icmp-rule"
      source_addresses      = ["*"]
      destination_ports     = ["*"]
      protocols             = ["ICMP"]
      destination_addresses = ["*"]
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "firewall_monitoring" {
  count                          = var.FwEnabled ? 1 : 0
  name                           = "ActivityLog-to-hub-law-${var.Region}"
  target_resource_id             = azurerm_firewall.firewall.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.law.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category = "AzureFirewallApplicationRule"
  }

  enabled_log {
    category = "AzureFirewallNetworkRule"
  }

  enabled_log {
    category = "AzureFirewallDnsProxy"
  }

  enabled_log {
    category = "AZFWNetworkRule"
  }

  enabled_log {
    category = "AZFWApplicationRule"
  }

  enabled_log {
    category = "AZFWNatRule"
  }

  enabled_log {
    category = "AZFWThreatIntel"
  }

  enabled_log {
    category = "AZFWIdpsSignature"
  }

  enabled_log {
    category = "AZFWDnsQuery"
  }

  enabled_log {
    category = "AZFWFqdnResolveFailure"
  }

  enabled_log {
    category = "AZFWFatFlow"
  }

  enabled_log {
    category = "AZFWFlowTrace"
  }

  enabled_log {
    category = "AZFWApplicationRuleAggregation"
  }

  enabled_log {
    category = "AZFWNetworkRuleAggregation"
  }

  enabled_log {
    category = "AZFWNatRuleAggregation"
  }

  metric {
    category = "allMetrics"
  }
}
