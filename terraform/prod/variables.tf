variable "AdminUsername" {
  default = "adminuser"
}

variable "AppVmName" {
  default = "app-prod-vm1"
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
  default = "spoke-prod-rg"
}

variable "VnetAddressSpace" {
  default = ["172.30.0.0/20"]
}

variable "VnetName" {
  default = "spoke-prod-vnet"
}

variable "WorkloadSubnetName" {
  default = "workload-subnet"
}

variable "WorkloadSubnetPrefix" {
  default = ["172.30.1.0/24"]
}

##### Sensitive Variables #####

variable "AdminPassword" {
  description = "The Password of the Dev VM"
  type        = string
}

variable "SubscriptionId" {
  description = "The Subscription ID for the environment"
  type        = string
}
