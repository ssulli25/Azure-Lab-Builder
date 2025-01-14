#===========#
# Resources #
#===========#

#================#
# Resource Group #
#================#

resource "azurerm_resource_group" "network_rg" {
  name     = var.NetworkRgName
  location = var.Region
}

resource "azurerm_resource_group" "monitor_rg" {
  name     = var.MonitorRgName
  location = var.Region
}

#============#
# Networking #
#============#

resource "azurerm_virtual_network" "vnet" {
  name                = var.VnetName
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
  address_space       = var.VnetAddressSpace
}

resource "azurerm_subnet" "mgmt" {
  name                 = "mgmt-subnet"
  resource_group_name = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.MgmtSubnetPrefix
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.GatewaySubnetPrefix
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name = azurerm_resource_group.network_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.BastionSubnetPrefix
}

resource "azurerm_virtual_network_gateway" "vng_gateway" {
  name                = var.VngName
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
  type                = var.VngType
  vpn_type            = var.VngVpnType
  sku                 = var.VngSku

  ip_configuration {
    name                 = "${var.VngName}-ipconfig"
    subnet_id            = azurerm_subnet.gateway.id
    public_ip_address_id = azurerm_public_ip.vng_pip.id
  }
}

resource "azurerm_public_ip" "vng_pip" {
  name                = "${var.VngName}-pip"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = var.BastionName
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location

  ip_configuration {
    name                 = "${var.BastionName}-ipconfig"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

resource "azurerm_public_ip" "bastion" {
  name                = "${var.BastionName}-pip"
  resource_group_name = azurerm_resource_group.network_rg.name
  location            = azurerm_resource_group.network_rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

#============#
# Monitoring #
#============#

resource "azurerm_log_analytics_workspace" "law" {
  name                = var.LogAnalyticsName
  resource_group_name = azurerm_resource_group.monitor_rg.name
  location            = azurerm_resource_group.monitor_rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "sub_diagnostic_settings" {
  name                       = "ActivityLog-to-${var.LogAnalyticsName}"
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
