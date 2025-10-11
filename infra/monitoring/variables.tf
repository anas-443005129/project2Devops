variable "subscription_id" {}
variable "rg_name" {}
variable "law_name" {}

variable "appgw_name" {}
variable "frontend_ca_name" {}
variable "backend_ca_name" {}

variable "sql_server_name" {}
variable "sql_database_name" {}



# optional – only if you wire action groups later
variable "alert_email"       {
     type = string
 default = null
  }
