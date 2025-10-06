variable "rg_name" { type = string }
variable "location" { type = string }

variable "vnet_name" { type = string }           # e.g., "anas-vnet"
variable "address_space" { type = list(string) } # e.g., ["10.0.0.0/16"]

# Subnet CIDRs
variable "aci_frontend_cidr" { type = string } # e.g., "10.0.1.0/24"
variable "aci_backend_cidr" { type = string }  # e.g., "10.0.2.0/24"
variable "agw_subnet_cidr" { type = string }   # e.g., "10.0.3.0/24"
