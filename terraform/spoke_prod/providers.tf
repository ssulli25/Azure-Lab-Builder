#===========================#
# Providers & Configuration #
#===========================#

terraform {
  # backend "azurerm" {}
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {
  }
}