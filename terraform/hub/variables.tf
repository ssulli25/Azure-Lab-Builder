variable "VnetAddressSpace" {
  type = list(string)
}

variable "BastionName" {
  default = "hub-bastion"
}

variable "BastionSubnetPrefix" {
  type = list(string)
}

variable "GatewaySubnetPrefix" {
  type = list(string)
}

variable "LogAnalyticsName" {
  default = "hub-law"
}

variable "MgmtSubnetPrefix" {
  type = list(string)
}

variable "Region" {
  default = "eastus2"
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

##### Sensitive Variables #####

variable "HubSubscriptionId" {
  description = "The Subscription ID for the environment"
  type        = string
}
