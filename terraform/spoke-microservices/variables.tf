##### Environment Variables #####

variable "EnvName" {
  type = string
}

variable "Region" {
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

##### Networking Variables #####

variable "VnetAddressSpace" {
  type = list(string)
}

variable "AksSystemSubnetPrefix" {
  type = list(string)
}

variable "AksUserSubnetPrefix" {
  type = list(string)
}

variable "AppGwSubnetPrefix" {
  type = list(string)
}

variable "PrivateEndpointSubnetPrefix" {
  type = list(string)
}

##### AKS Variables #####

variable "AksKubernetesVersion" {
  type = string
}

variable "AksSystemNodeVmSize" {
  type = string
}

variable "AksUserNodeVmSize" {
  type = string
}

variable "AksUserNodeMin" {
  type = number
}

variable "AksUserNodeMax" {
  type = number
}

variable "AksPodCidr" {
  type        = string
  description = "Overlay pod CIDR; must NOT overlap any VNet/subnet/peered network."
}

variable "AksServiceCidr" {
  type = string
}

variable "AksDnsServiceIp" {
  type = string
}

##### Container Registry / Data / Security Variables #####

variable "AcrSku" {
  type = string
}

variable "SqlDatabaseSku" {
  type = string
}

variable "SqlAdminLogin" {
  description = "SQL Server administrator login (username)"
  type        = string
}

##### Sensitive Variables #####

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

variable "AdminPassword" {
  description = "Password used as the Azure SQL Server administrator_login_password in the microservices spoke."
  type        = string
  sensitive   = true
}
