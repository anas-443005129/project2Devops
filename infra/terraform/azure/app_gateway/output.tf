output "id"        { value = azurerm_application_gateway.agw.id }
output "public_ip" { value = azurerm_public_ip.pip.ip_address }
output "public_fqdn" { value = azurerm_public_ip.pip.fqdn }
