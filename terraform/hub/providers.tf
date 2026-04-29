#===========================#
# Providers & Configuration #
#===========================#

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  subscription_id = var.HubSubscriptionId
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}