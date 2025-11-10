# Outputs for the main deployment
# Use these values to populate the additional-projects/terraform.tfvars file

output "storage_account_id" {
  description = "The resource ID of the Storage Account"
  value       = azurerm_storage_account.storage_account.id
}

output "cosmosdb_account_id" {
  description = "The resource ID of the Cosmos DB Account"
  value       = azurerm_cosmosdb_account.cosmosdb.id
}

output "ai_search_id" {
  description = "The resource ID of the AI Search service"
  value       = azapi_resource.ai_search.id
}

output "ai_foundry_id" {
  description = "The resource ID of the AI Foundry hub"
  value       = azapi_resource.ai_foundry.id
}

output "resource_ids_for_additional_projects" {
  description = "Copy these values to additional-projects/terraform.tfvars"
  value = <<-EOT
  
  # Add these to additional-projects/terraform.tfvars:
  storage_account_id  = "${azurerm_storage_account.storage_account.id}"
  cosmosdb_account_id = "${azurerm_cosmosdb_account.cosmosdb.id}"
  ai_search_id        = "${azapi_resource.ai_search.id}"
  ai_foundry_id       = "${azapi_resource.ai_foundry.id}"
  EOT
}
