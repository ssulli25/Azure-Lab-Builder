variable "AdminUsername" {
  default = "adminuser"
}

variable "AppVmName" {
  default = "app-dev-vm1"
}

variable "AppVmSize" {
  default = "Standard_B2ms"
}

variable "HubRg" {
  default = "hub-rg"
}

variable "HubVnet" {
  default = "hub-vnet"
}

variable "Region" {
  default = "eastus"
}

variable "ResourceGroupName" {
  default = "spoke-dev-rg"
}

variable "VnetAddressSpace" {
  default = ["172.20.0.0/20"]
}

variable "VnetName" {
  default = "spoke-dev-vnet"
}

variable "WorkloadSubnetName" {
  default = "workload-subnet"
}

variable "WorkloadSubnetPrefix" {
  default = ["172.20.1.0/24"]
}

##### Sensitive Variables #####

variable "AdminPassword" {
  description = "The Password of the Dev VM"
  type        = string
}

variable "DevSubscriptionId" {
  description = "The Subscription ID for the Dev environment"
  type        = string
}

variable "HubSubscriptionId" {
  description = "The Subscription ID for the Hub environment"
  type        = string
}

