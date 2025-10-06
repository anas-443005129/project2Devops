output "server_fqdn" { value = azurerm_mssql_server.dbserver.fully_qualified_domain_name }
output "db_name" { value = azurerm_mssql_database.db.name }
output "admin_username" { value = azurerm_mssql_server.dbserver.administrator_login }
