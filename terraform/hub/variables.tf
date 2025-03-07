variable "AzFirewallMgmtSubnetPrefix" {
  type = list(string)
}

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

variable "FwEnabled" {
  type = bool
}

variable "GatewaySubnetPrefix" {
  type = list(string)
}

variable "MgmtSubnetPrefix" {
  type = list(string)
}

variable "Region" {
  type = string
}

variable "VnetAddressSpace" {
  type = list(string)
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
