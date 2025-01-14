variable "VnetAddressSpace" {
  type = list(string)
}

variable "BastionName" {
  type = string
}

variable "BastionSubnetPrefix" {
  type = list(string)
}

variable "GatewaySubnetPrefix" {
  type = list(string)
}

variable "LogAnalyticsName" {
  type = string
}

variable "NetworkRgName" {
  type = string
}

variable "MgmtSubnetPrefix" {
  type = list(string)
}

variable "MonitorRgName" {
  type = string
}

variable "Region" {
  type = string
}

variable "VnetName" {
  type = string
}

variable "VngName" {
  type = string
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
