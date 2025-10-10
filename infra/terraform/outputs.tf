
output "app_gateway_public_ip" {
  description = "Public IP address - USE THIS TO ACCESS YOUR APP"
  value       = azurerm_public_ip.appgw.ip_address
}


output "rg_name" {
  value = module.resource_group.resource_group.name
}

output "appgw_name" {
  value = module.application_gateway.name # or expose from the module's outputs
}

output "appgw_public_ip" {
  value = azurerm_public_ip.appgw.ip_address
}

output "frontend_url" {
  description = "Frontend application URL"
  value       = "http://${azurerm_public_ip.appgw.ip_address}"
}

output "backend_api_url" {
  description = "Backend API URL"
  value       = "http://${azurerm_public_ip.appgw.ip_address}/api"
}

output "health_check_url" {
  description = "Backend health check URL"
  value       = "http://${azurerm_public_ip.appgw.ip_address}/actuator/health"
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.resource_group.name
}

output "sql_server_name" {
  description = "Name of the SQL Server"
  value       = module.sql_server.server_name
}

output "sql_database_name" {
  description = "Name of the SQL Database"
  value       = module.sql_server.database_name
}

output "aca_infrastructure_subnet_prefixes" {
  value = module.subnets["app_subnet"].subnet.address_prefixes
}
