
module "resource_group" {
  source   = "./modules/resource_group"
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "vnet" {
  source              = "./modules/virtual_network"
  name                = var.vnet_name
  resource_group_name = module.resource_group.resource_group.name
  location            = var.location
  address_space       = var.address_space
  tags                = var.tags
}

module "subnets" {
  source              = "./modules/subnets"
  for_each            = var.subnet
  name                = each.key
  resource_group_name = module.resource_group.resource_group.name
  vnet_name           = module.vnet.virtual_network.name
  address_prefixes    = each.value.address_space
}



module "log_analytics" {
  source              = "./modules/log_analytics"
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = module.resource_group.resource_group.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

module "sql_server" {
  source              = "./modules/sql_server"
  server_name         = var.sql_server_name
  resource_group_name = module.resource_group.resource_group.name
  location            = var.location
  admin_username      = var.sql_admin_username
  admin_password      = var.sql_admin_password
  database_name       = var.sql_database_name
  subnet_id           = module.subnets["db_subnet"].subnet.id
  virtual_network_id  = module.vnet.virtual_network.id
  tags                = var.tags
  depends_on = [
    module.resource_group,
    module.vnet,
    module.subnets # for the Private Endpoint subnet
  ]

}



module "container_app_environment" {
  source                         = "./modules/container_app_environment"
  name                           = var.container_app_environment_name
  location                       = var.location
  resource_group_name            = module.resource_group.resource_group.name
  log_analytics_workspace_id     = module.log_analytics.id
  infrastructure_subnet_id       = module.subnets["app_subnet"].subnet.id
  internal_load_balancer_enabled = false
  tags                           = var.tags
  depends_on = [
    module.resource_group,
    module.vnet,
    module.subnets,
    module.log_analytics
  ]

}


resource "azurerm_public_ip" "appgw" {
  name                = "${var.app_gateway_name}-pip"
  resource_group_name = module.resource_group.resource_group.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}


module "container_apps" {
  source   = "./modules/container_apps"
  for_each = var.container_apps

  name                         = "${each.key}-app"
  container_name               = each.key
  container_app_environment_id = module.container_app_environment.id
  resource_group_name          = module.resource_group.resource_group.name

  image  = each.value.image
  cpu    = each.value.cpu
    log_analytics_workspace_id = module.log_analytics.id

  memory = each.value.memory

  min_replicas = each.value.min_replicas
  max_replicas = each.value.max_replicas
  ip_security_restrictions = each.key == "backend" ? [
    {
      name             = "AllowFromAGW"
      description      = "Only traffic from Application Gateway"
      action           = "Allow"                                      # keep exactly "Allow"
      ip_address_range = "${azurerm_public_ip.appgw.ip_address}/32"   # AGW public IP
    }
  ] : []


  ingress_enabled            = true
  external_enabled           = true
  target_port                = each.value.target_port
  allow_insecure_connections = true

  env_vars = merge(
    each.value.env_vars,
    each.key == "backend" ? {
      DB_HOST              = module.sql_server.server_private_fqdn
      DB_PORT              = "1433"
      DB_NAME              = module.sql_server.database_name
      DB_USERNAME          = var.sql_admin_username
      DB_PASSWORD          = var.sql_admin_password
      DB_DRIVER            = "com.microsoft.sqlserver.jdbc.SQLServerDriver"
      CORS_ALLOWED_ORIGINS = "http://${azurerm_public_ip.appgw.ip_address}"
            APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.apps["backend"].connection_string

    } : {},
    each.key == "frontend" ? {
      VITE_API_BASE_URL = "http://${azurerm_public_ip.appgw.ip_address}"
            APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.apps["frontend"].connection_string

    } : {}
  )


  tags = var.tags

  depends_on = [
    module.container_app_environment,
    module.sql_server,
    azurerm_public_ip.appgw
  ]


}

module "application_gateway" {
  source              = "./modules/application_gateway"
  name                = var.app_gateway_name
  resource_group_name = module.resource_group.resource_group.name
  location            = var.location
  subnet_id           = module.subnets["appgw_subnet"].subnet.id
  sku                 = var.app_gateway_sku
  log_analytics_workspace_id = module.log_analytics.id

  public_ip_id = azurerm_public_ip.appgw.id

  frontend_fqdn = module.container_apps["frontend"].fqdn
  backend_fqdn  = module.container_apps["backend"].fqdn

  frontend_health_path = "/"
  backend_health_path  = "/actuator/health"

  tags = var.tags

  depends_on = [module.container_apps,
  azurerm_public_ip.appgw]
}



resource "azurerm_application_insights" "apps" {
  for_each            = { frontend = true, backend = true }
  name                = "${each.key}-appi"
  location            = var.location
  resource_group_name = module.resource_group.resource_group.name
  application_type    = "web"
  workspace_id        = module.log_analytics.id
  retention_in_days   = 30
}
