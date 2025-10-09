# Application Gateway (Public IP is now passed as a variable)
resource "azurerm_application_gateway" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  sku {
    name     = var.sku.name
    tier     = var.sku.tier
    capacity = var.sku.capacity
  }

  gateway_ip_configuration {
    name      = "${var.name}-ip-config"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "${var.name}-frontend-ip"
    public_ip_address_id = var.public_ip_id
  }

  backend_address_pool {
    name  = "frontend-backend-pool"
    fqdns = [var.frontend_fqdn]
  }

  backend_address_pool {
    name  = "backend-backend-pool"
    fqdns = [var.backend_fqdn]
  }

  backend_http_settings {
    name                  = "frontend-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 60
    probe_name            = "frontend-health-probe"
    pick_host_name_from_backend_address = true
  }

  # Backend HTTP Settings for Backend API
  backend_http_settings {
    name                  = "backend-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 60
    probe_name            = "backend-health-probe"
    pick_host_name_from_backend_address = true
  }


  rewrite_rule_set {
    name = "api-rewrite-rules"
    
    rewrite_rule {
      name          = "strip-api-prefix"
      rule_sequence = 100
      
      condition {
        variable    = "var_uri_path"
        pattern     = "^/api/(.*)"
        ignore_case = true
      }
      
      url {
        path = "/{var_uri_path_1}"
      }
    }
  }

  probe {
  name                                      = "frontend-health-probe"
  protocol                                  = "Https"
  path                                      = "/"                 # ← your choice
  interval                                  = 30
  timeout                                   = 30
  unhealthy_threshold                       = 3
  pick_host_name_from_backend_http_settings = true
  match {
    status_code = ["200-399"]
  }
}

probe {
  name        = "backend-health-probe"
  protocol    = "Https"
  path        = "/actuator/health"
  interval    = 30
  timeout     = 30
  unhealthy_threshold = 3
  pick_host_name_from_backend_http_settings = true
  match {
    status_code = ["200-399"]
  }
}

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "${var.name}-frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  url_path_map {
    name                               = "path-based-routing"
    default_backend_address_pool_name  = "frontend-backend-pool"
    default_backend_http_settings_name = "frontend-http-settings"

    path_rule {
      name                       = "api-routing"
      paths                      = ["/api/*"]
      backend_address_pool_name  = "backend-backend-pool"
      backend_http_settings_name = "backend-http-settings"
      rewrite_rule_set_name      = "api-rewrite-rules"
    }

    path_rule {
      name                       = "actuator-routing"
      paths                      = ["/actuator/*"]
      backend_address_pool_name  = "backend-backend-pool"
      backend_http_settings_name = "backend-http-settings"
    }
  }

  request_routing_rule {
    name                       = "path-based-routing-rule"
    rule_type                  = "PathBasedRouting"
    http_listener_name         = "http-listener"
    url_path_map_name          = "path-based-routing"
    priority                   = 100
  }
}
