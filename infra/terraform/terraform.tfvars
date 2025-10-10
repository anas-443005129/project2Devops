subscription_id     = "4421688c-0a8d-4588-8dd0-338c5271d0af"
resource_group_name = "rg-capstone-devanas-423"
location            = "westeurope"
tags = {
  environment = "dev"
  project     = "capstone"
}

vnet_name     = "anas-vnet"
address_space = ["10.0.0.0/16"]

subnet = {
  appgw_subnet = { address_space = ["10.0.20.0/24"] }
  app_subnet   = { address_space = ["10.0.8.0/23"] }  # was /24
  db_subnet    = { address_space = ["10.0.12.0/24"] } # fine for PE
}

log_analytics_workspace_name = "capstone-log-analytics"

container_app_environment_name = "capstone-container-app-env"

container_apps = {
  frontend = {
    image            = "anasabdullahalzahrani/three-tier-frontend:latest"
    cpu              = 0.5
    memory           = "1.0Gi"
    target_port      = 80
    external_enabled = true
    min_replicas     = 1
    max_replicas     = 3
    env_vars         = {}
  }
  backend = {
    image            = "anasabdullahalzahrani/three-tier-backend:latest"
    cpu              = 1.0
    memory           = "2.0Gi"
    target_port      = 8080
    external_enabled = false
    min_replicas     = 1
    max_replicas     = 3
    env_vars         = {}
  }
}

app_gateway_name = "anasburgerbuilderappgw"
app_gateway_sku = {
  name     = "Standard_v2"
  tier     = "Standard_v2"
  capacity = 2
}

sql_server_name    = "anassqlserver"
sql_database_name  = "capstoneans"
sql_admin_username = "sqladminans"
sql_admin_password = "P@ssw0rd-ChangeMe123!"
