variable "VnetAddressSpace" {
  default = ["10.1.0.0/20"]
}

variable "BastionName" {
  default = "hub-bastion"
}

variable "BastionSubnetPrefix" {
  default = ["10.1.3.0/24"]
}

variable "GatewaySubnetPrefix" {
  default = ["10.1.2.0/24"]
}

variable "LogAnalyticsName" {
  default = "hub-law"
}

variable "MgmtSubnetPrefix" {
  default = ["10.1.1.0/24"]
}

variable "Region" {
  default = "eastus"
}

variable "ResourceGroupName" {
  default = "hub-rg"
}

variable "VnetName" {
  default = "hub-vnet"
}

variable "VngName" {
  default = "hub-vng"
}

variable "VngSku" {
  default = "VpnGw1"
}

variable "VngType" {
  default = "Vpn"
}

variable "VngVpnType" {
  default = "RouteBased"
}