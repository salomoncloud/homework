locals{
  loadbalancerconfig=[for f in fileset("${path.module}/loadbalancer", "[^_]*.yaml") : yamldecode(file("${path.module}/loadbalancer/${f}"))]
  loadbalancerlist = flatten([
    for app in local.loadbalancerconfig : [
      for loadbalancer in try(app.loadbalancerconfiguration, []) :{
        name=loadbalancer.publicipname
        allocation_method=loadbalancer.allocation_method

      }
    ]
])
}
resource "azurerm_resource_group" "loadbalancerrg" {
  name     = "LoadBalancerRG"
  location = "West Europe"
}

resource "azurerm_public_ip" "azurepublicipexample" {
  for_each            = {for publicip in local.loadbalancerlist: "${publicip.name}"=>publicip }
  name                = each.value.name
  location            = azurerm_resource_group.loadbalancerrg.location
  resource_group_name = azurerm_resource_group.loadbalancerrg.name
  allocation_method   = each.value.allocation_method
}

resource "azurerm_lb" "azureloadbalancerexample" {
  for_each            = azurerm_public_ip.azurepublicipexample
  name                = each.value.name
  location            = azurerm_resource_group.loadbalancerrg.location
  resource_group_name = azurerm_resource_group.loadbalancerrg.name
  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = each.value.id
  }
}
