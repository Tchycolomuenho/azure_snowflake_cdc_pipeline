provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-cdc-snowflake"
  location = "eastus"
}

resource "azurerm_data_factory" "adf" {
  name                = "adf-cdc-snowflake"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  identity { type = "SystemAssigned" }
}

resource "azurerm_storage_account" "landing" {
  name                     = "cdclanding${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

# Exemplos: roles/warehouse em Snowflake podem ser declarados via provider snowflake
# resource "snowflake_database" "raw" { name = "RAW" }
