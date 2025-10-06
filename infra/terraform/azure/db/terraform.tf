resource "azurerm_mssql_server" "dbserver" {
  name                          = "${var.db_name}-sqlsrv"
  resource_group_name           = var.rg_name
  location                      = var.rg_location
  version                       = "12.0"
  administrator_login           = var.admin_username
  administrator_login_password  = var.admin_password
  public_network_access_enabled = false
}

resource "azurerm_mssql_database" "db" {
  name      = var.db_name
  server_id = azurerm_mssql_server.dbserver.id
  sku_name  = "S0"
  collation = "SQL_Latin1_General_CP1_CI_AS"
}

# Private DNS zone for SQL
resource "azurerm_private_dns_zone" "sql_privatelink" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_link" {
  name                  = "sql-plink"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.sql_privatelink.name
  virtual_network_id    = var.vnet_id
}

# PE subnet for Private Endpoint
resource "azurerm_subnet" "pe_subnet" {
  name                 = "pe-subnet"
  resource_group_name  = var.rg_name
  virtual_network_name = var.vnet_name
  address_prefixes     = ["10.0.10.0/24"]
}

# Private Endpoint to SQL server
resource "azurerm_private_endpoint" "pe_database" {
  name                = "db-pe"
  location            = var.rg_location
  resource_group_name = var.rg_name
  subnet_id           = azurerm_subnet.pe_subnet.id

  private_service_connection {
    name                           = "dbserver-psc"
    private_connection_resource_id = azurerm_mssql_server.dbserver.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "sql-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql_privatelink.id]
  }
}
