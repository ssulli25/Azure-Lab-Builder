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

provider "azurerm" {
  subscription_id = var.SubscriptionId
  features {
  }
}