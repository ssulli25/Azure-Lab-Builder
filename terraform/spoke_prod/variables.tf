variable "AdminUsername" {
  default = "adminuser"
}

variable "AdminPassword" {
  default = "HolderPa$$4Lab"
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