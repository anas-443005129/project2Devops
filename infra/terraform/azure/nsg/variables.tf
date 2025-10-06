variable "rg_name" { type = string }
variable "location" { type = string }
variable "agw_subnet_prefix" { type = string } # to allow AGW → ACI
variable "aci_fe_subnet_id" { type = string }
variable "aci_be_subnet_id" { type = string }
