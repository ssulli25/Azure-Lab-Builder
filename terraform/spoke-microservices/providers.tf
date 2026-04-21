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

### Primary provider for resources
provider "azurerm" {
  subscription_id = var.SubscriptionId
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

### Secondary provider for resources in hub subscription
provider "azurerm" {
  alias           = "hub"
  subscription_id = var.HubSubscriptionId
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
