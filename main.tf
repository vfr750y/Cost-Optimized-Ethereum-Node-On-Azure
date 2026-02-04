# 1. Create the Virtual Network
resource "azurerm_virtual_network" "node_vnet" {
  name                = "ethereum-node-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# 2. Create a delegated Subnet
resource "azurerm_subnet" "aci_subnet" {
  name                 = "aci-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.node_vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "aci-delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# 3. Deploy ACI into that Subnet
resource "azurerm_container_group" "helios_node" {
  name                = "helios-light-node"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Private" # Important: Sets it to internal only
  network_profile_id  = azurerm_network_profile.aci_profile.id
  os_type             = "Linux"

  container {
    name   = "helios"
    image  = "a16z/helios:latest"
    cpu    = "1"
    memory = "2"
    ports {
      port     = 8545
      protocol = "TCP"
    }
  }
}