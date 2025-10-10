resource "azurerm_container_app" "app" {
  name                         = var.name
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = var.revision_mode

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = var.container_name
      image  = var.image
      cpu    = var.cpu
      memory = var.memory

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }
    }
  }

  # ONE ingress block only
  dynamic "ingress" {
    for_each = var.ingress_enabled ? [1] : []
    content {
      external_enabled           = var.external_enabled
      target_port                = var.target_port
      allow_insecure_connections = var.allow_insecure_connections

      traffic_weight {
        percentage      = 100
        latest_revision = true
      }

      # keep all actions the same ("ALLOW") for an allow-list
      dynamic "ip_security_restriction" {
        for_each = var.ip_security_restrictions
        content {
          name             = ip_security_restriction.value.name
          description      = lookup(ip_security_restriction.value, "description", null)
          action           = ip_security_restriction.value.action # "Allow"
          ip_address_range = ip_security_restriction.value.ip_address_range
        }
      }

    }
  }

  tags = var.tags
}

