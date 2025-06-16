resource "azurerm_network_security_group" "rdp_test_nsg" {
  name                = "cloudguard-test-nsg"
  location            = azurerm_resource_group.remediation_rg.location
  resource_group_name = azurerm_resource_group.remediation_rg.name

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
