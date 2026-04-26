### Windows build template (data tier) ###
#
# Plugin and variable declarations live in _shared.pkr.hcl so that
# this template and build-linux.pkr.hcl can coexist in the same
# directory without duplicate-declaration errors.

source "azure-arm" "windows" {
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

  winrm_username = var.build["az_configs"].communicator.winrm_username
  winrm_password = var.build["az_configs"].communicator.winrm_password
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "10m"
  winrm_port     = 5986

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
  sources = ["source.azure-arm.windows"]

  provisioner "powershell" {
    scripts = [var.script_file]
  }

  # Generalize the Windows image so it can be deployed as a template.
  provisioner "powershell" {
    inline = [
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit /mode:vm",
      "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10 } else { break } }"
    ]
  }

}
