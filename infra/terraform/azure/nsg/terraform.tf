resource "azurerm_network_security_group" "aci_fe" {
  name                = "nsg-aci-fe"
  location            = var.location
  resource_group_name = var.rg_name

  security_rule {
    name                       = "allow-http-from-agw"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.agw_subnet_prefix
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "aci_be" {
  name                = "nsg-aci-be"
  location            = var.location
  resource_group_name = var.rg_name

  security_rule {
    name                       = "allow-api-from-agw"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = var.agw_subnet_prefix
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "fe_assoc" {
  subnet_id                 = var.aci_fe_subnet_id
  network_security_group_id = azurerm_network_security_group.aci_fe.id
}

resource "azurerm_subnet_network_security_group_association" "be_assoc" {
  subnet_id                 = var.aci_be_subnet_id
  network_security_group_id = azurerm_network_security_group.aci_be.id
}
