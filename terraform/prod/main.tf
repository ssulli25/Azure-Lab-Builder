#======#
# Data #
#======#

data "azurerm_virtual_network" "hub" {
  name                = var.HubVnet
  resource_group_name = var.HubRg
}

#===========#
# Resources #
#===========#

#================#
# Resource Group #
#================#

resource "azurerm_resource_group" "rg" {
  name     = var.ResourceGroupName
  location = var.Region
}

#============#
# Networking #
#============#

resource "azurerm_virtual_network" "vnet" {
  name                = var.VnetName
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = var.VnetAddressSpace
}

resource "azurerm_subnet" "workload" {
  name                 = "workload-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.WorkloadSubnetPrefix
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "hub-to-spoke-prod"
  resource_group_name          = var.HubRg
  virtual_network_name         = data.azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "spoke-dev-to-prod"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = data.azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
}

#=========#
# Compute #
#=========#

resource "azurerm_windows_virtual_machine" "app_vm" {
  name                  = var.AppVmName
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = var.AppVmSize
  admin_username        = var.AdminUsername
  admin_password        = var.AdminPassword
  network_interface_ids = [azurerm_network_interface.app_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_network_interface" "app_nic" {
  name                = "nic-${var.AppVmName}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "nic-${var.AppVmName}-config1"
    subnet_id                     = azurerm_subnet.workload.id
    private_ip_address_allocation = "Dynamic"
  }
}
