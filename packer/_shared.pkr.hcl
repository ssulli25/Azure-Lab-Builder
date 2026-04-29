#===========================#
# Providers & Configuration #
#===========================#
#
# Shared declarations loaded by every Packer build in this directory.
# Both build-linux.pkr.hcl and build-windows.pkr.hcl rely on these.
#

packer {
  required_plugins {
    azure = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/azure"
    }
    ansible = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}


### Variables Section ###

#############################################################################
# Tenant
#############################################################################

variable "tenant_id" {
  type = string
}

#############################################################################
# Subscription
#############################################################################

variable "subscription_id" {
  type = string
}

#############################################################################
# Client Id + Secret
#############################################################################

variable "client_id" {
  type = string
}
variable "client_secret" {
  type = string
}

#############################################################################
# Build
#############################################################################

variable "build" {}

#############################################################################
# Per-OS provisioner inputs
#
# - playbook_file is consumed by build-linux.pkr.hcl (Ansible).
#############################################################################

variable "playbook_file" {
  type    = string
  default = ""
}
