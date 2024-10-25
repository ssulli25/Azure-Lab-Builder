variable "AppGwSubnetPrefix" {
  type = list(string)
}

variable "AppLbSubnetPrefix" {
  type = list(string)
}

variable "AppSubnetPrefix" {
  type = list(string)
}

variable "DataLbSubnetPrefix" {
  type = list(string)
}

variable "DataSubnetPrefix" {
  type = list(string)
}

variable "DbVmSize" {
  type = string
}

variable "EnvName" {
  type = string
}

variable "HubEnabled" {
  type    = bool
  default = false
}

variable "HubNetworkRg" {
  type = string
}

variable "HubVnet" {
  type = string
}

variable "LinuxInstanceCount" {
  type = number
}

variable "LinuxVmssSize" {
  type = string
}

variable "Region" {
  type = string
}

variable "VnetAddressSpace" {
  type = list(string)
}

variable "WebSubnetPrefix" {
  type = list(string)
}

variable "WebInstanceCount" {
  type = number
}

variable "WebVmssSize" {
  type = string
}

##### Sensitive Variables #####

variable "AdminPassword" {
  description = "The Password of the Compute Instance"
  type        = string
  sensitive   = true
}

variable "AdminUsername" {
  description = "The Username of the Compute Instance"
  type        = string
  sensitive   = true
}

variable "SubscriptionId" {
  description = "The Subscription ID for the given environment"
  type        = string
  sensitive   = true
}

variable "HubSubscriptionId" {
  description = "The Subscription ID for the Hub environment (if applicable)"
  type        = string
  sensitive   = true
}
