variable "AzFwTier" {
  type = string
}

variable "AzFirewallSubnetPrefix" {
  type = list(string)
}

variable "BastionEnabled" {
  type = bool
}

variable "BastionSubnetPrefix" {
  type = list(string)
}

variable "DevAddressSpace" {
  type = string
}

variable "FwEnabled" {
  type = bool
}

variable "GatewaySubnetPrefix" {
  type = list(string)
}

variable "MgmtSubnetPrefix" {
  type = list(string)
}

variable "ProdAddressSpace" {
  type = string
}

variable "Region" {
  type = string
}

variable "VnetAddressSpace" {
  type = list(string)
}

variable "VngEnabled" {
  type = bool
}

variable "VngSku" {
  type = string
}

variable "VngType" {
  type = string
}

variable "VngVpnType" {
  type = string
}

##### Sensitive Variables #####

variable "HubSubscriptionId" {
  description = "The Subscription ID for the environment"
  type        = string
  sensitive   = true
}
