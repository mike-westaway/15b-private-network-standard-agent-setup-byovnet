# Outputs for the additional projects

output "project_ids" {
  description = "Map of project names to their resource IDs"
  value = {
    for name, project in azapi_resource.ai_foundry_project : name => project.id
  }
}

output "project_names" {
  description = "List of project names created"
  value = [
    for name, project in azapi_resource.ai_foundry_project : project.name
  ]
}

output "project_internal_ids" {
  description = "Map of project names to their internal IDs (GUIDs)"
  value = {
    for name, project in azapi_resource.ai_foundry_project : name => project.output.properties.internalId
  }
}

output "project_principal_ids" {
  description = "Map of project names to their managed identity principal IDs"
  value = {
    for name, project in azapi_resource.ai_foundry_project : name => project.output.identity.principalId
  }
}

output "project_details" {
  description = "Detailed information about all created projects"
  value = {
    for name, project in azapi_resource.ai_foundry_project : name => {
      id                = project.id
      name              = project.name
      internal_id       = project.output.properties.internalId
      principal_id      = project.output.identity.principalId
      project_id_guid   = local.project_id_guids[name]
      storage_container = azurerm_storage_container.project_container[name].name
      search_index      = azapi_resource.project_search_index[name].name
    }
  }
}

output "storage_containers" {
  description = "Map of project names to their dedicated storage container names"
  value = {
    for name, container in azurerm_storage_container.project_container : name => container.name
  }
}

output "search_indexes" {
  description = "Map of project names to their dedicated AI Search index names"
  value = {
    for name, index in azapi_resource.project_search_index : name => index.name
  }
}
