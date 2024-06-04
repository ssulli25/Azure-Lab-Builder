#===========================#
# Providers & Configuration #
#===========================#

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

### Primary provider for resources
provider "azurerm" {
  subscription_id = var.DevSubscriptionId
  features {
  }
}

### Secondary provider for resources in hub subscription
provider "azurerm" {
  alias           = "hub"
  subscription_id = var.HubSubscriptionId
  features {}
}