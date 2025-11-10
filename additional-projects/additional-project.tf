########## Create the AI Foundry project, project connections, role assignments, and project-level capability host
##########

## Create AI Foundry projects (one for each name in the project_names list)
##
resource "azapi_resource" "ai_foundry_project" {
  for_each = local.projects
  
  provider = azapi.workload_subscription

  type                      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name                      = each.value
  parent_id                 = data.azapi_resource.ai_foundry.id
  location                  = var.location
  schema_validation_enabled = false

  body = {
    sku = {
      name = "S0"
    }
    identity = {
      type = "SystemAssigned"
    }

    properties = {
      displayName = each.value
      description = "A project for the AI Foundry account with network secured deployed Agent"
    }
  }

  response_export_values = [
    "identity.principalId",
    "properties.internalId"
  ]
}

## Wait 10 seconds for the AI Foundry project system-assigned managed identity to be created and to replicate
## through Entra ID
resource "time_sleep" "wait_project_identities" {
  for_each = local.projects
  
  depends_on = [
    azapi_resource.ai_foundry_project
  ]
  create_duration = "10s"
}

## Create dedicated storage containers for each project
##
resource "azurerm_storage_container" "project_container" {
  for_each = local.projects
  
  provider = azurerm.workload_subscription
  
  name                  = "${each.value}-container"
  storage_account_id    = data.azurerm_storage_account.storage_account.id
  container_access_type = "private"
}

## Create dedicated AI Search indexes for each project
##
resource "azapi_resource" "project_search_index" {
  for_each = local.projects
  
  provider = azapi.workload_subscription

  type      = "Microsoft.Search/searchServices/indexes@2024-07-01"
  name      = "${each.value}-index"
  parent_id = data.azapi_resource.ai_search.id

  body = {
    properties = {
      fields = [
        {
          name       = "id"
          type       = "Edm.String"
          key        = true
          searchable = false
          filterable = false
          sortable   = false
          facetable  = false
        },
        {
          name       = "content"
          type       = "Edm.String"
          searchable = true
          filterable = false
          sortable   = false
          facetable  = false
        },
        {
          name       = "content_vector"
          type       = "Collection(Edm.Single)"
          searchable = true
          dimensions = 1536
          vectorSearchProfile = "vector-profile"
        },
        {
          name       = "metadata"
          type       = "Edm.String"
          searchable = false
          filterable = true
          sortable   = false
          facetable  = false
        }
      ]
      vectorSearch = {
        algorithms = [
          {
            name = "vector-algorithm"
            kind = "hnsw"
          }
        ]
        profiles = [
          {
            name      = "vector-profile"
            algorithm = "vector-algorithm"
          }
        ]
      }
    }
  }

  schema_validation_enabled = false
}

## Create AI Foundry project connections
##
resource "azapi_resource" "conn_cosmosdb" {
  for_each = local.projects
  
  provider = azapi.workload_subscription

  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name                      = data.azurerm_cosmosdb_account.cosmosdb.name
  parent_id                 = azapi_resource.ai_foundry_project[each.key].id
  schema_validation_enabled = false

  depends_on = [
    azapi_resource.ai_foundry_project
  ]

  body = {
    name = data.azurerm_cosmosdb_account.cosmosdb.name
    properties = {
      category = "CosmosDb"
      target   = data.azurerm_cosmosdb_account.cosmosdb.endpoint
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ResourceId = data.azurerm_cosmosdb_account.cosmosdb.id
        location   = var.location
      }
    }
  }
}

## Create the AI Foundry project connection to Azure Storage Account
##
resource "azapi_resource" "conn_storage" {
  for_each = local.projects
  
  provider = azapi.workload_subscription

  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name                      = data.azurerm_storage_account.storage_account.name
  parent_id                 = azapi_resource.ai_foundry_project[each.key].id
  schema_validation_enabled = false

  depends_on = [
    azapi_resource.ai_foundry_project
  ]

  body = {
    name = data.azurerm_storage_account.storage_account.name
    properties = {
      category = "AzureStorageAccount"
      target   = data.azurerm_storage_account.storage_account.primary_blob_endpoint
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ResourceId = data.azurerm_storage_account.storage_account.id
        location   = var.location
      }
    }
  }

  response_export_values = [
    "identity.principalId"
  ]
}

## Create the AI Foundry project connection to AI Search
##
resource "azapi_resource" "conn_aisearch" {
  for_each = local.projects
  
  provider = azapi.workload_subscription

  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name                      = data.azapi_resource.ai_search.name
  parent_id                 = azapi_resource.ai_foundry_project[each.key].id
  schema_validation_enabled = false

  depends_on = [
    azapi_resource.ai_foundry_project
  ]

  body = {
    name = data.azapi_resource.ai_search.name
    properties = {
      category = "CognitiveSearch"
      target   = "https://${data.azapi_resource.ai_search.name}.search.windows.net"
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ApiVersion = "2025-05-01-preview"
        ResourceId = data.azapi_resource.ai_search.id
        location   = var.location
      }
    }
  }

  response_export_values = [
    "identity.principalId"
  ]
}

## Create the necessary role assignments for the AI Foundry project over the resources used to store agent data
##
resource "azurerm_role_assignment" "cosmosdb_operator_ai_foundry_project" {
  for_each = local.projects
  
  provider = azurerm.workload_subscription

  depends_on = [
    resource.time_sleep.wait_project_identities
  ]
  name                 = uuidv5("dns", "${azapi_resource.ai_foundry_project[each.key].name}${azapi_resource.ai_foundry_project[each.key].output.identity.principalId}${var.resource_group_name_resources}cosmosdboperator")
  scope                = data.azurerm_cosmosdb_account.cosmosdb.id
  role_definition_name = "Cosmos DB Operator"
  principal_id         = azapi_resource.ai_foundry_project[each.key].output.identity.principalId
}

resource "azurerm_role_assignment" "storage_blob_data_contributor_project_container" {
  for_each = local.projects
  
  provider = azurerm.workload_subscription

  depends_on = [
    resource.time_sleep.wait_project_identities,
    azurerm_storage_container.project_container
  ]
  name                 = uuidv5("dns", "${azapi_resource.ai_foundry_project[each.key].name}${azapi_resource.ai_foundry_project[each.key].output.identity.principalId}${azurerm_storage_container.project_container[each.key].name}containerblobdatacontributor")
  scope                = azurerm_storage_container.project_container[each.key].resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azapi_resource.ai_foundry_project[each.key].output.identity.principalId
}

resource "azurerm_role_assignment" "search_index_data_contributor_project_index" {
  for_each = local.projects
  
  provider = azurerm.workload_subscription

  depends_on = [
    resource.time_sleep.wait_project_identities,
    azapi_resource.project_search_index
  ]
  name                 = uuidv5("dns", "${azapi_resource.ai_foundry_project[each.key].name}${azapi_resource.ai_foundry_project[each.key].output.identity.principalId}${azapi_resource.project_search_index[each.key].name}indexdatacontributor")
  scope                = azapi_resource.project_search_index[each.key].id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = azapi_resource.ai_foundry_project[each.key].output.identity.principalId
}

resource "azurerm_role_assignment" "search_index_data_reader_project_index" {
  for_each = local.projects
  
  provider = azurerm.workload_subscription

  depends_on = [
    resource.time_sleep.wait_project_identities,
    azapi_resource.project_search_index
  ]
  name                 = uuidv5("dns", "${azapi_resource.ai_foundry_project[each.key].name}${azapi_resource.ai_foundry_project[each.key].output.identity.principalId}${azapi_resource.project_search_index[each.key].name}indexdatareader")
  scope                = azapi_resource.project_search_index[each.key].id
  role_definition_name = "Search Index Data Reader"
  principal_id         = azapi_resource.ai_foundry_project[each.key].output.identity.principalId
}

## Pause 60 seconds to allow for role assignments to propagate
##
resource "time_sleep" "wait_rbac" {
  for_each = local.projects
  
  depends_on = [
    azurerm_role_assignment.cosmosdb_operator_ai_foundry_project,
    azurerm_role_assignment.storage_blob_data_contributor_project_container,
    azurerm_role_assignment.search_index_data_contributor_project_index,
    azurerm_role_assignment.search_index_data_reader_project_index
  ]
  create_duration = "60s"
}

## Create the AI Foundry project capability host
##
resource "azapi_resource" "ai_foundry_project_capability_host" {
  for_each = local.projects
  
  provider = azapi.workload_subscription

  depends_on = [
    azapi_resource.conn_aisearch,
    azapi_resource.conn_cosmosdb,
    azapi_resource.conn_storage,
    time_sleep.wait_rbac
  ]
  type                      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-04-01-preview"
  name                      = "caphostproj"
  parent_id                 = azapi_resource.ai_foundry_project[each.key].id
  schema_validation_enabled = false

  body = {
    properties = {
      capabilityHostKind = "Agents"
      vectorStoreConnections = [
        data.azapi_resource.ai_search.name
      ]
      storageConnections = [
        data.azurerm_storage_account.storage_account.name
      ]
      threadStorageConnections = [
        data.azurerm_cosmosdb_account.cosmosdb.name
      ]
    }
  }
}

## Create the necessary data plane role assignments to the CosmosDb databases created by the AI Foundry Project
##
resource "azurerm_cosmosdb_sql_role_assignment" "cosmosdb_db_sql_role_aifp_user_thread_message_store" {
  for_each = local.projects
  
  provider = azurerm.workload_subscription

  depends_on = [
    azapi_resource.ai_foundry_project_capability_host
  ]
  name                = uuidv5("dns", "${azapi_resource.ai_foundry_project[each.key].name}${azapi_resource.ai_foundry_project[each.key].output.identity.principalId}userthreadmessage_dbsqlrole")
  resource_group_name = var.resource_group_name_resources
  account_name        = data.azurerm_cosmosdb_account.cosmosdb.name
  scope               = "${data.azurerm_cosmosdb_account.cosmosdb.id}/dbs/enterprise_memory/colls/${local.project_id_guids[each.key]}-thread-message-store"
  role_definition_id  = "${data.azurerm_cosmosdb_account.cosmosdb.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azapi_resource.ai_foundry_project[each.key].output.identity.principalId
}

resource "azurerm_cosmosdb_sql_role_assignment" "cosmosdb_db_sql_role_aifp_system_thread_name" {
  for_each = local.projects
  
  provider = azurerm.workload_subscription

  depends_on = [
    azurerm_cosmosdb_sql_role_assignment.cosmosdb_db_sql_role_aifp_user_thread_message_store
  ]
  name                = uuidv5("dns", "${azapi_resource.ai_foundry_project[each.key].name}${azapi_resource.ai_foundry_project[each.key].output.identity.principalId}systemthread_dbsqlrole")
  resource_group_name = var.resource_group_name_resources
  account_name        = data.azurerm_cosmosdb_account.cosmosdb.name
  scope               = "${data.azurerm_cosmosdb_account.cosmosdb.id}/dbs/enterprise_memory/colls/${local.project_id_guids[each.key]}-system-thread-message-store"
  role_definition_id  = "${data.azurerm_cosmosdb_account.cosmosdb.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azapi_resource.ai_foundry_project[each.key].output.identity.principalId
}

resource "azurerm_cosmosdb_sql_role_assignment" "cosmosdb_db_sql_role_aifp_entity_store_name" {
  for_each = local.projects
  
  provider = azurerm.workload_subscription

  depends_on = [
    azurerm_cosmosdb_sql_role_assignment.cosmosdb_db_sql_role_aifp_system_thread_name
  ]
  name                = uuidv5("dns", "${azapi_resource.ai_foundry_project[each.key].name}${azapi_resource.ai_foundry_project[each.key].output.identity.principalId}entitystore_dbsqlrole")
  resource_group_name = var.resource_group_name_resources
  account_name        = data.azurerm_cosmosdb_account.cosmosdb.name
  scope               = "${data.azurerm_cosmosdb_account.cosmosdb.id}/dbs/enterprise_memory/colls/${local.project_id_guids[each.key]}-agent-entity-store"
  role_definition_id  = "${data.azurerm_cosmosdb_account.cosmosdb.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azapi_resource.ai_foundry_project[each.key].output.identity.principalId
}

## Create the necessary data plane role assignments to the project-specific storage containers
##
resource "azurerm_role_assignment" "storage_blob_data_owner_project_container" {
  for_each = local.projects
  
  provider = azurerm.workload_subscription

  depends_on = [
    azapi_resource.ai_foundry_project_capability_host,
    azurerm_storage_container.project_container
  ]
  name                 = uuidv5("dns", "${azapi_resource.ai_foundry_project[each.key].name}${azapi_resource.ai_foundry_project[each.key].output.identity.principalId}${azurerm_storage_container.project_container[each.key].name}containerblobdataowner")
  scope                = azurerm_storage_container.project_container[each.key].resource_manager_id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azapi_resource.ai_foundry_project[each.key].output.identity.principalId
}
