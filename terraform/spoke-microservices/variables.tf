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
  type    = string
  default = null
}

variable "AksSystemNodeVmSize" {
  type    = string
  default = "Standard_D2s_v5"
}

variable "AksUserNodeVmSize" {
  type    = string
  default = "Standard_D4s_v5"
}

variable "AksUserNodeMin" {
  type    = number
  default = 1
}

variable "AksUserNodeMax" {
  type    = number
  default = 3
}

variable "AksPodCidr" {
  type        = string
  description = "Overlay pod CIDR; must NOT overlap any VNet/subnet/peered network."
  default     = "100.64.0.0/16"
}

variable "AksServiceCidr" {
  type    = string
  default = "172.16.0.0/16"
}

variable "AksDnsServiceIp" {
  type    = string
  default = "172.16.0.10"
}

##### Container Registry / Data / Security Variables #####

variable "AcrSku" {
  type    = string
  default = "Premium"
}

variable "SqlDatabaseSku" {
  type    = string
  default = "GP_S_Gen5_2"
}

variable "SqlAadAdminLogin" {
  description = "Display name of the Entra ID user/group to assign as Azure SQL AAD admin"
  type        = string
}

variable "SqlAadAdminObjectId" {
  description = "Object ID of the Entra ID user/group to assign as Azure SQL AAD admin"
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

# Accepted for cross-architecture workflow compatibility (not used by AKS/SQL stack).
variable "AdminPassword" {
  description = "Unused in microservices spoke; kept for workflow var-passing parity with 3-tier."
  type        = string
  sensitive   = true
  default     = ""
}
