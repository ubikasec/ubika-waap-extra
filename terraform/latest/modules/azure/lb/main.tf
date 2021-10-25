variable "resource_group" {}
variable "subnet" {}
variable "mapping" {}
variable "healthcheck_path" { default = "" }

resource "random_id" "healthcheck" {
  prefix      = "lb-health-"
  byte_length = 16
}

# Load Balancer
resource "random_string" "fqdn" {
  length  = 6
  special = false
  upper   = false
  number  = false
  lower   = true
}

resource "azurerm_public_ip" "public_ip" {
  name                = "PublicIPForLB"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  allocation_method   = "Static"
  domain_name_label   = random_string.fqdn.result
  sku                 = "Standard"

}

resource "azurerm_lb" "lb" {
  name                = "lb"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name            = "backend_pool"
  loadbalancer_id = azurerm_lb.lb.id
}

resource "azurerm_lb_probe" "lb_probe" {
  count = length(var.mapping)

  resource_group_name = var.resource_group.name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "lb_probe-${var.mapping[count.index].dest}"
  port                = var.mapping[count.index].dest
  protocol            = var.mapping[count.index].proto
  request_path        = var.healthcheck_path != "" ? var.healthcheck_path : "/${random_id.healthcheck.hex}"
}

resource "azurerm_lb_rule" "lb_rule" {
  count = length(var.mapping)

  resource_group_name            = var.resource_group.name
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "lb_rule-${var.mapping[count.index].dest}"
  protocol                       = "Tcp"
  frontend_port                  = var.mapping[count.index].src
  backend_port                   = var.mapping[count.index].dest
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_pool.id
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = azurerm_lb_probe.lb_probe[count.index].id
}

output "backend_pool_id" {
  value = azurerm_lb_backend_address_pool.backend_pool.id
}
output "public_url" {
  value       = "http://${azurerm_public_ip.public_ip.fqdn}/"
  description = "Public acces to your application"
}

output "healthcheck" {
  value       = var.healthcheck_path != "" ? var.healthcheck_path : "/${random_id.healthcheck.hex}"
  description = "Loadbalancers healthchecks path"
}
