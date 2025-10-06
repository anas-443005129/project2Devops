output "subnet_agw_id"       { value = azurerm_subnet.agw.id }
output "subnet_aci_frontend_id" { value = azurerm_subnet.aci_frontend.id }
output "subnet_aci_backend_id"  { value = azurerm_subnet.aci_backend.id }
output "vnet_id"             { value = azurerm_virtual_network.vnet.id }

# ✨ add this to satisfy module.nsg
output "subnet_agw_prefix"   { value = azurerm_subnet.agw.address_prefixes[0] }
