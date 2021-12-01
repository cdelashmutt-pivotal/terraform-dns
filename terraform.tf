# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

data "azurerm_subscription" "current" {
}

data "azuread_client_config" "current" {
}

# Create a resource group
resource "azurerm_resource_group" "example" {
  name     = "dns"
  location = "East US"
}

resource "azurerm_dns_zone" "azure-grogscave-net" {
  name                = "azure.grogscave.net"
  resource_group_name = azurerm_resource_group.example.name
}

# Creates Service Prinicpal
resource "azuread_application" "auth" {
  display_name = "auth"
  owners = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "auth" {
  application_id = "${azuread_application.auth.application_id}"
  owners = [data.azuread_client_config.current.object_id]
}

resource "azurerm_role_assignment" "dns_contrib_for_auth" {
  scope                = azurerm_dns_zone.azure-grogscave-net.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azuread_service_principal.auth.id
}

resource "azuread_service_principal_password" "auth" {
  service_principal_id = "${azuread_service_principal.auth.id}"
}

output "app_id" {
  value = azuread_application.auth.application_id
  description = "SP App ID"
}

output "sp_password" {
  value = azuread_service_principal_password.auth.value
  description = "SP Password"
  sensitive = true
}

output "subscription_id" {
  value = data.azurerm_subscription.current.subscription_id
  description = "Subscription ID"
}

output "tenant_id" {
  value = data.azurerm_subscription.current.tenant_id
  description = "Tenant ID"
}

output "dns_zone" {
  value = azurerm_dns_zone.azure-grogscave-net.name
  description = "DNS Zone"
}

output "dns_zone_resource_group" {
  value = azurerm_dns_zone.azure-grogscave-net.resource_group_name
  description = "DNS Resource Group"
}