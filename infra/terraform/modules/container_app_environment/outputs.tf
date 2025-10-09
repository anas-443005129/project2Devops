output "id" {
  description = "ID of the Container App Environment"
  value       = azurerm_container_app_environment.main.id
}

# keep this one
output "default_domain" {
  value = azurerm_container_app_environment.main.default_domain
}

# FIX this one
output "static_ip_address" {
  value = azurerm_container_app_environment.main.static_ip_address
}


output "name" {
  description = "Name of the Container App Environment"
  value       = azurerm_container_app_environment.main.name
}
