locals {
  # Convert project names list to a map for for_each
  projects = { for name in var.project_names : name => name }
  
  # Create a map of project GUIDs for each project
  project_id_guids = {
    for name, project in azapi_resource.ai_foundry_project : name => "${substr(project.output.properties.internalId, 0, 8)}-${substr(project.output.properties.internalId, 8, 4)}-${substr(project.output.properties.internalId, 12, 4)}-${substr(project.output.properties.internalId, 16, 4)}-${substr(project.output.properties.internalId, 20, 12)}"
  }
}
