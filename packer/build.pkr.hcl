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
# Playbook
#############################################################################

variable "playbook_file" {}


### Build file for Packer ###

source "azure-arm" "build" {
  azure_tags                        = var.build["azure_tags"]
  client_id                         = var.client_id
  client_secret                     = var.client_secret
  subscription_id                   = var.subscription_id
  tenant_id                         = var.tenant_id
  communicator                      = var.build["az_configs"].communicator.type
  image_offer                       = var.build["az_configs"].image_offer
  image_publisher                   = var.build["az_configs"].image_publisher
  image_sku                         = var.build["az_configs"].image_sku
  location                          = var.build["az_configs"].location
  managed_image_name                = var.build["az_configs"].managed_image_name
  managed_image_resource_group_name = var.build["az_configs"].managed_image_resource_group_name
  os_type                           = var.build["az_configs"].os_type
  vm_size                           = var.build["az_configs"].vm_size
  ssh_username                      = var.build["az_configs"].communicator.type == "ssh" ? var.build["az_configs"]["communicator"].ssh_username : null
  ssh_password                      = var.build["az_configs"].communicator.type == "ssh" ? var.build["az_configs"]["communicator"].ssh_password : null
  winrm_password                    = var.build["az_configs"].communicator.type != "ssh" ? var.build["az_configs"]["communicator"].winrm_password : null
  winrm_username                    = var.build["az_configs"].communicator.type != "ssh" ? var.build["az_configs"]["communicator"].winrm_username : null

  dynamic "shared_image_gallery_destination" {
    for_each = contains(keys(var.build), "shared_image_galleries") ? var.build["shared_image_galleries"] : {}
    iterator = g
    content {
      subscription        = g.value["subscription"]
      resource_group      = g.value["resource_group"]
      gallery_name        = g.value["gallery_name"]
      image_name          = g.value["image_name"]
      image_version       = g.value["image_version"]
      replication_regions = g.value["replication_regions"]
    }
  }

}

build {
  sources = ["source.azure-arm.build"]

  provisioner "ansible" {

    playbook_file = var.playbook_file
    extra_arguments = [
      "-vvv"
    ]
  }

}
