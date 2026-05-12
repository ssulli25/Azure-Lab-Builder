variable "AppGwSubnetPrefix" {
  type = list(string)
}

variable "AppLbSubnetPrefix" {
  type = list(string)
}

variable "AppSubnetPrefix" {
  type = list(string)
}

variable "AppImageId" {
  type = string
}

variable "AppInstanceCount" {
  type = number
}

variable "AppVmssSize" {
  type = string
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

variable "FwEnabled" {
  type    = bool
  default = false
}

variable "HubEnabled" {
  type    = bool
  default = false
}

variable "Region" {
  type = string
}

variable "VnetAddressSpace" {
  type = list(string)
}

variable "WebImageId" {
  type = string
}

variable "WebInstanceCount" {
  type = number
}

variable "WebSubnetPrefix" {
  type = list(string)
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
