resource "azurerm_public_ip" "pip" {
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_application_gateway" "agw" {
  name                = var.name
  location            = var.location
  resource_group_name = var.rg_name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "gw-ipcfg"
    subnet_id = var.subnet_id
  }

  frontend_ip_configuration {
    name                 = "fe-ip"
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  # -------------------- Backend pools (ACI private IPs) --------------------
  backend_address_pool {
    name         = "pool-frontend"
    ip_addresses = var.fe_backend_ips
  }

  backend_address_pool {
    name         = "pool-backend"
    ip_addresses = var.be_backend_ips
  }

  # -------------------- HTTP settings --------------------
  backend_http_settings {
    name                                = "http-frontend"
    protocol                            = "Http"
    port                                = var.fe_port
    cookie_based_affinity               = "Disabled"
    pick_host_name_from_backend_address = false
    request_timeout                     = 30
    probe_name                          = "probe-frontend"
  }

  backend_http_settings {
    name                                = "http-backend"
    protocol                            = "Http"
    port                                = var.be_port
    cookie_based_affinity               = "Disabled"
    pick_host_name_from_backend_address = false
    request_timeout                     = 30
    probe_name                          = "probe-backend"
  }

  # -------------------- Probes (no host header for IP targets) --------------------
  probe {
    name                = "probe-frontend"
    protocol            = "Http"
    path                = "/"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
  }

  probe {
    name                = "probe-backend"
    protocol            = "Http"
    path                = "/api/health"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
  }

  # -------------------- Listener / rules --------------------
  http_listener {
    name                           = "listener-http"
    frontend_ip_configuration_name = "fe-ip"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  url_path_map {
    name                               = "paths"
    default_backend_address_pool_name  = "pool-frontend"
    default_backend_http_settings_name = "http-frontend"

    path_rule {
      name                       = "api"
      paths                      = ["/api/*"]
      backend_address_pool_name  = "pool-backend"
      backend_http_settings_name = "http-backend"
    }
  }

  request_routing_rule {
    name               = "rule-path"
    rule_type          = "PathBasedRouting"
    http_listener_name = "listener-http"
    url_path_map_name  = "paths"
    priority           = 100
  }
}
