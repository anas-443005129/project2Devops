# azure/app_gateway/variables.tf
variable "name"       { type = string }
variable "rg_name"    { type = string }
variable "location"   { type = string }
variable "subnet_id"  { type = string }
variable "fe_backend_ips" { type = list(string) }
variable "be_backend_ips" { type = list(string) }
variable "fe_port" { 
    type = number
 default = 80
 }
variable "be_port" {
     type = number
 default = 8080
  }
