# ------------------ Resource Group ------------------
module "rg" {
  source   = "./azure/resourcegroup"
  rg_name  = var.rg_name     # e.g. "rg-capstone-dev"
  location = var.rg_location # e.g. "westeurope"
}

# ------------------ VNet (with ACI delegations) ------------------
module "vnet" {
  source   = "./azure/Vnet"
  rg_name  = module.rg.rg_name
  location = module.rg.rg_location

  vnet_name     = "anas-vnet"
  address_space = ["10.0.0.0/16"]

  aci_frontend_cidr = "10.0.1.0/24"
  aci_backend_cidr  = "10.0.2.0/24"
  agw_subnet_cidr   = "10.0.3.0/24"
}

# ------------------ NSGs for ACI subnets ------------------
module "nsg" {
  source            = "./azure/nsg"
  rg_name           = module.rg.rg_name
  location          = module.rg.rg_location
  agw_subnet_prefix = module.vnet.subnet_agw_prefix
  aci_fe_subnet_id  = module.vnet.subnet_aci_frontend_id
  aci_be_subnet_id  = module.vnet.subnet_aci_backend_id
}

# ------------------ ACI: Frontend ------------------
module "aci_fe" {
  source    = "./azure/aci_service"
  name      = "fe-aci"
  rg_name   = module.rg.rg_name
  location  = module.rg.rg_location
  subnet_id = module.vnet.subnet_aci_frontend_id
  image     = var.fe_image
  ports     = [80]

  # no cycle with AppGW – FE can call /api/* and the gateway routes it
  env = { VITE_API_BASE_URL = "/" }

  # only needed if Docker Hub is private / rate-limiting you
  registry_username = var.dockerhub_username
  registry_password = var.dockerhub_token
}

module "aci_be" {
  source    = "./azure/aci_service"
  name      = "be-aci"
  rg_name   = module.rg.rg_name
  location  = module.rg.rg_location
  subnet_id = module.vnet.subnet_aci_backend_id
  image     = var.be_image
  ports     = [8080]

  registry_username = var.dockerhub_username
  registry_password = var.dockerhub_token
}

# ------------------ Application Gateway ------------------
module "app_gateway" {
  source    = "./azure/app_gateway"
  name      = "agw-capstone"
  rg_name   = module.rg.rg_name
  location  = module.rg.rg_location
  subnet_id = module.vnet.subnet_agw_id

  fe_backend_ips = [module.aci_fe.ip] # ACI FE private IP
  be_backend_ips = [module.aci_be.ip] # ACI BE private IP
  fe_port        = 80
  be_port        = 8080
}
