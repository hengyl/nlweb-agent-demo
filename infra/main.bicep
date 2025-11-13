targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@description('Location for all resources')
// Based on the model, creating an agent is not supported in all regions. 
// The combination of allowed and usageName below is for AZD to check AI model gpt-4o-mini quota only for the allowed regions for creating an agent.
// If using different models, update the SKU,capacity depending on the model you use.
// https://learn.microsoft.com/azure/ai-services/agents/concepts/model-region-support
@allowed([
  'eastus'
  'eastus2'
  'swedencentral'
  'westus2'
])
@metadata({
  azd: {
    type: 'location'
    // quota-validation for ai models: gpt-4o-mini
    usageName: [
      'OpenAI.GlobalStandard.gpt-4o-mini,80'
    ]
  }
})
param location string

@description('Use this parameter to use an existing AI project resource ID')
param azureExistingAIProjectResourceId string = ''
@description('The Azure resource group where new resources will be deployed')
param resourceGroupName string = ''
@description('The Azure AI Foundry Hub resource name. If ommited will be generated')
param aiProjectName string = ''
@description('The application insights resource name. If ommited will be generated')
param applicationInsightsName string = ''
@description('The AI Services resource name. If ommited will be generated')
param aiServicesName string = ''
@description('The Azure Search resource name. If ommited will be generated')
param searchServiceName string = ''
@description('The log analytics workspace name. If ommited will be generated')
param logAnalyticsWorkspaceName string = ''
@description('Id of the user or app to assign application roles')
param principalId string = ''

// Chat completion model
@description('Format of the chat model to deploy')
@allowed(['Microsoft', 'OpenAI'])
param agentModelFormat string = 'OpenAI'
@description('ID of the existing agent')
param azureExistingAgentId string = ''
@description('Name of the chat model to deploy')
param agentModelName string = 'gpt-4o-mini'
@description('Name of the model deployment')
param agentDeploymentName string = 'gpt-4o-mini'

@description('Version of the chat model to deploy')
// See version availability in this table:
// https://learn.microsoft.com/azure/ai-services/openai/concepts/models#global-standard-model-availability
param agentModelVersion string = '2024-07-18'

@description('Sku of the chat deployment')
param agentDeploymentSku string = 'GlobalStandard'

@description('Capacity of the chat deployment')
// You can increase this, but capacity is limited per model/region, so you will get errors if you go over
// https://learn.microsoft.com/en-us/azure/ai-services/openai/quotas-limits
param agentDeploymentCapacity int = 30

// Embedding model
@description('Format of the embedding model to deploy')
@allowed(['Microsoft', 'OpenAI'])
param embedModelFormat string = 'OpenAI'

@description('Name of the embedding model to deploy')
param embedModelName string = 'text-embedding-3-small'
@description('Name of the embedding model deployment')
param embeddingDeploymentName string = 'text-embedding-3-small'

@description('Version of the embedding model to deploy')
// See version availability in this table:
// https://learn.microsoft.com/azure/ai-services/openai/concepts/models#embeddings-models
param embedModelVersion string = '1'

@description('Sku of the embeddings model deployment')
param embedDeploymentSku string = 'Standard'

@description('Capacity of the embedding deployment')
// You can increase this, but capacity is limited per model/region, so you will get errors if you go over
// https://learn.microsoft.com/azure/ai-services/openai/quotas-limits
param embedDeploymentCapacity int = 60

param useApplicationInsights bool = true
@description('Do we want to use the Azure AI Search')
param useSearchService bool = true

@description('Do we want to use the Azure Monitor tracing')
param enableAzureMonitorTracing bool = false

@description('Do we want to use the Azure Monitor tracing for GenAI content recording')
param azureTracingGenAIContentRecordingEnabled bool = false

param templateValidationMode bool = false

@description('Random seed to be used during generation of new resources suffixes.')
param seed string = newGuid()

var runnerPrincipalType = templateValidationMode? 'ServicePrincipal' : 'User'

var abbrs = loadJsonContent('./abbreviations.json')

var resourceToken = templateValidationMode? toLower(uniqueString(subscription().id, environmentName, location, seed)) :  toLower(uniqueString(subscription().id, environmentName, location))

var tags = { 'azd-env-name': environmentName }

var aiChatModel = [
  {
    name: agentDeploymentName
    model: {
      format: agentModelFormat
      name: agentModelName
      version: agentModelVersion
    }
    sku: {
      name: agentDeploymentSku
      capacity: agentDeploymentCapacity
    }
  }
]
var aiEmbeddingModel = [ 
  {
    name: embeddingDeploymentName
    model: {
      format: embedModelFormat
      name: embedModelName
      version: embedModelVersion
    }
    sku: {
      name: embedDeploymentSku
      capacity: embedDeploymentCapacity
    }
  }
]

var aiDeployments = concat(
  aiChatModel,
  useSearchService ? aiEmbeddingModel : [])


// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

var logAnalyticsWorkspaceResolvedName = !useApplicationInsights
  ? ''
  : !empty(logAnalyticsWorkspaceName)
      ? logAnalyticsWorkspaceName
      : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'

var resolvedSearchServiceName = !useSearchService
  ? ''
  : !empty(searchServiceName) ? searchServiceName : '${abbrs.searchSearchServices}${resourceToken}'
  
var acrResourceName = '${abbrs.containerRegistryRegistries}${resourceToken}'

module ai 'core/host/ai-environment.bicep' = if (empty(azureExistingAIProjectResourceId)) {
  name: 'ai'
  scope: rg
  params: {
    location: location
    tags: tags
    aiServicesName: !empty(aiServicesName) ? aiServicesName : 'aoai-${resourceToken}'
    aiProjectName: !empty(aiProjectName) ? aiProjectName : 'proj-${resourceToken}'
    aiServiceModelDeployments: aiDeployments
    logAnalyticsName: logAnalyticsWorkspaceResolvedName
    applicationInsightsName: !useApplicationInsights
      ? ''
      : !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    searchServiceName: resolvedSearchServiceName
    acrResourceName: acrResourceName
    appInsightConnectionName: 'appinsights-connection'
    aoaiConnectionName: 'aoai-connection'
  }
}

var searchServiceEndpoint = !useSearchService
  ? ''
  : empty(azureExistingAIProjectResourceId) ? ai!.outputs.searchServiceEndpoint : ''

// If bringing an existing AI project, set up the log analytics workspace here
module logAnalytics 'core/monitor/loganalytics.bicep' = if (!empty(azureExistingAIProjectResourceId)) {
  name: 'logAnalytics'
  scope: rg
  params: {
    location: location
    tags: tags
    name: logAnalyticsWorkspaceResolvedName
  }
}
var existingProjEndpoint = !empty(azureExistingAIProjectResourceId) ? format('https://{0}.services.ai.azure.com/api/projects/{1}',split(azureExistingAIProjectResourceId, '/')[8], split(azureExistingAIProjectResourceId, '/')[10]) : ''

var projectResourceId = !empty(azureExistingAIProjectResourceId)
  ? azureExistingAIProjectResourceId
  : ai!.outputs.projectResourceId

var projectEndpoint = !empty(azureExistingAIProjectResourceId)
  ? existingProjEndpoint
  : ai!.outputs.aiProjectEndpoint

var aoaiEndpoint = replace(projectEndpoint, '/api/projects/${last(split(projectEndpoint, '/'))}', '')

var acrLoginServer = ai!.outputs.containerRegistryLoginServer

var resolvedApplicationInsightsName = !useApplicationInsights || !empty(azureExistingAIProjectResourceId)
  ? ''
  : !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'

resource existingProjectRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = if (!empty(azureExistingAIProjectResourceId) && contains(azureExistingAIProjectResourceId, '/')) {
  name: split(azureExistingAIProjectResourceId, '/')[4]
}

resource existingProjectResource 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' existing = if (!empty(azureExistingAIProjectResourceId)) {
  scope: existingProjectRG
  name: '${split(azureExistingAIProjectResourceId, '/')[8]}/${split(azureExistingAIProjectResourceId, '/')[10]}'
}

var projectPrincipalId = !empty(azureExistingAIProjectResourceId)
  ? existingProjectResource.identity.principalId
  : ai!.outputs.aiProjectPrincipalId

module projectRoleAcrPull  'core/security/role.bicep' = {
name: 'project-role-acr-pull'
scope: rg
params: {
  principalType: 'ServicePrincipal'
  principalId: projectPrincipalId
  roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}
}

module projectRoleAzureAIUser  'core/security/role.bicep' = {
  name: 'project-role-azure-ai-user'
  scope: rg
  params: {
    principalType: 'ServicePrincipal'
    principalId: projectPrincipalId
    roleDefinitionId: '53ca6127-db72-4b80-b1b0-d745d6d5456d'
  }
}

module projectRoleSearchIndexDataContributorRG 'core/security/role.bicep' = if (useSearchService) {
  name: 'project-role-azure-index-data-contributor-rg'
  scope: rg
  params: {
    principalType: 'ServicePrincipal'
    principalId: projectPrincipalId
    roleDefinitionId: '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
  }
}

module userRoleAzureAIDeveloper 'core/security/role.bicep' = {
  name: 'user-role-azureai-developer'
  scope: rg
  params: {
    principalType: runnerPrincipalType
    principalId: principalId
    roleDefinitionId: '64702f94-c441-49e6-a78b-ef80e0188fee'
  }
}

module userCognitiveServicesUser  'core/security/role.bicep' = if (empty(azureExistingAIProjectResourceId)) {
  name: 'user-role-cognitive-services-user'
  scope: rg
  params: {
    principalType: runnerPrincipalType
    principalId: principalId
    roleDefinitionId: 'a97b65f3-24c7-4388-baec-2e87135dc908'
  }
}

module userAzureAIUser  'core/security/role.bicep' = if (empty(azureExistingAIProjectResourceId)) {
  name: 'user-role-azure-ai-user'
  scope: rg
  params: {
    principalType: runnerPrincipalType
    principalId: principalId
    roleDefinitionId: '53ca6127-db72-4b80-b1b0-d745d6d5456d'
  }
}

module userRoleSearchIndexDataContributorRG 'core/security/role.bicep' = if (useSearchService) {
  name: 'user-role-azure-index-data-contributor-rg'
  scope: rg
  params: {
    principalType: runnerPrincipalType
    principalId: principalId
    roleDefinitionId: '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
  }
}

module userRoleSearchIndexDataReaderRG 'core/security/role.bicep' = if (useSearchService) {
  name: 'user-role-azure-index-data-reader-rg'
  scope: rg
  params: {
    principalType: runnerPrincipalType
    principalId: principalId
    roleDefinitionId: '1407120a-92aa-4202-b7e9-c0e197c71c8f'
  }
}

module userRoleSearchServiceContributorRG 'core/security/role.bicep' = if (useSearchService) {
  name: 'user-role-azure-search-service-contributor-rg'
  scope: rg
  params: {
    principalType: runnerPrincipalType
    principalId: principalId
    roleDefinitionId: '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
  }
}

output AZURE_RESOURCE_GROUP string = rg.name

// Outputs required for local development server
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_AI_AGENT_DEPLOYMENT_NAME string = agentDeploymentName
output AZURE_AI_EMBED_DEPLOYMENT_NAME string = embeddingDeploymentName
output AZURE_AI_SEARCH_ENDPOINT string = searchServiceEndpoint
output AZURE_OPENAI_ENDPOINT string = aoaiEndpoint
output ENABLE_AZURE_MONITOR_TRACING bool = enableAzureMonitorTracing
output AZURE_TRACING_GEN_AI_CONTENT_RECORDING_ENABLED bool = azureTracingGenAIContentRecordingEnabled
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acrLoginServer
output AI_FOUNDRY_PROJECT_RESOURCE_ID string = projectResourceId
output AZURE_AI_FOUNDRY_PROJECT_ID string = projectResourceId
output AZURE_AI_PROJECT_ENDPOINT string = projectEndpoint
