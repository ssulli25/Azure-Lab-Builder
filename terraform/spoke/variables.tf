variable "AdminUsername" {
  default = "adminuser"
}

variable "AppVmSize" {
  default = "Standard_B2ms"
}

variable "EnvName" {
  type = string
}

variable "HubEnabled" {
  default = false
}

variable "HubRg" {
  default = "hub-rg"
}

variable "HubVnet" {
  default = "hub-vnet"
}

variable "Region" {
  default = "eastus2"
}

variable "VnetAddressSpace" {
  type = list(string)
}

variable "WorkloadSubnetName" {
  default = "workload-subnet"
}

variable "WorkloadSubnetPrefix" {
  type = list(string)
}

##### Sensitive Variables #####

variable "AdminPassword" {
  description = "The Password of the Dev VM"
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
