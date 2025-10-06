resource "azurerm_container_group" "cg" {
  name                = var.name
  location            = var.location
  resource_group_name = var.rg_name
  os_type             = "Linux"

  # Private IP in your VNet
  ip_address_type = "Private"
  subnet_ids      = [var.subnet_id]

  # Only add registry creds if a username is provided
  dynamic "image_registry_credential" {
    for_each = var.registry_username != "" ? [1] : []
    content {
      server   = var.registry_server
      username = var.registry_username
      password = var.registry_password
    }
  }

  container {
    name   = "app"
    image  = var.image
    cpu    = var.cpu
    memory = var.memory

    environment_variables = var.env

    dynamic "ports" {
      for_each = var.ports
      content {
        port     = ports.value
        protocol = "TCP"
      }
    }
  }
}
