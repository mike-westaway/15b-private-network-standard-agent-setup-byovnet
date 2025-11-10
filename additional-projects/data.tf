# Data sources to reference existing resources

data "azurerm_storage_account" "storage_account" {
  provider = azurerm.workload_subscription

  name                = split("/", var.storage_account_id)[8]
  resource_group_name = var.resource_group_name_resources
}

data "azurerm_cosmosdb_account" "cosmosdb" {
  provider = azurerm.workload_subscription

  name                = split("/", var.cosmosdb_account_id)[8]
  resource_group_name = var.resource_group_name_resources
}

data "azapi_resource" "ai_search" {
  provider = azapi.workload_subscription

  type      = "Microsoft.Search/searchServices@2025-05-01"
  resource_id = var.ai_search_id
}

data "azapi_resource" "ai_foundry" {
  provider = azapi.workload_subscription

  type      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  resource_id = var.ai_foundry_id
}
