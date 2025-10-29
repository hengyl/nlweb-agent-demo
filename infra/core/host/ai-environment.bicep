@minLength(1)
@description('Primary location for all resources')
param location string

@description('The AI Project resource name.')
param aiProjectName string
@description('The AI Services resource name.')
param aiServicesName string
@description('The AI Services model deployments.')
param aiServiceModelDeployments array = []
@description('The Log Analytics resource name.')
param logAnalyticsName string = ''
@description('The Application Insights resource name.')
param applicationInsightsName string = ''
@description('The Azure Search resource name.')
param searchServiceName string = ''
@description('The Application Insights connection name.')
param appInsightConnectionName string
param tags object = {}
param aoaiConnectionName string

module logAnalytics '../monitor/loganalytics.bicep' =
  if (!empty(logAnalyticsName)) {
    name: 'logAnalytics'
    params: {
      location: location
      tags: tags
      name: logAnalyticsName
    }
  }

module applicationInsights '../monitor/applicationinsights.bicep' =
  if (!empty(applicationInsightsName) && !empty(logAnalyticsName)) {
    name: 'applicationInsights'
    params: {
      location: location
      tags: tags
      name: applicationInsightsName
      logAnalyticsWorkspaceId: !empty(logAnalyticsName) ? logAnalytics.outputs.id : ''
    }
  }


module cognitiveServices '../ai/cognitiveservices.bicep' = {
  name: 'cognitiveServices'
  params: {
    location: location
    tags: tags
    aiServiceName: aiServicesName
    aiProjectName: aiProjectName
    deployments: aiServiceModelDeployments
    appInsightsId: applicationInsights.outputs.id
    appInsightConnectionName: appInsightConnectionName
    appInsightConnectionString: applicationInsights.outputs.connectionString
    aoaiConnectionName: aoaiConnectionName
  }
}

module searchService '../search/search-services.bicep' =
  if (!empty(searchServiceName)) {
    dependsOn: [cognitiveServices]
    name: 'searchService'
    params: {
      location: location
      tags: tags
      name: searchServiceName
      semanticSearch: 'free'
      authOptions: { aadOrApiKey: { aadAuthFailureMode: 'http401WithBearerChallenge'}}
      projectName: cognitiveServices.outputs.projectName
      serviceName: cognitiveServices.outputs.serviceName
    }
  }


// Outputs
output applicationInsightsId string = !empty(applicationInsightsName) ? applicationInsights.outputs.id : ''
output applicationInsightsName string = !empty(applicationInsightsName) ? applicationInsights.outputs.name : ''
output logAnalyticsWorkspaceId string = !empty(logAnalyticsName) ? logAnalytics.outputs.id : ''
output logAnalyticsWorkspaceName string = !empty(logAnalyticsName) ? logAnalytics.outputs.name : ''

output aiServiceId string = cognitiveServices.outputs.id
output aiServicesName string = cognitiveServices.outputs.name
output aiProjectEndpoint string = cognitiveServices.outputs.projectEndpoint
output aiServicePrincipalId string = cognitiveServices.outputs.accountPrincipalId

output searchServiceId string = !empty(searchServiceName) ? searchService.outputs.id : ''
output searchServiceName string = !empty(searchServiceName) ? searchService.outputs.name : ''
output searchServiceEndpoint string = !empty(searchServiceName) ? searchService.outputs.endpoint : ''

output projectResourceId string = cognitiveServices.outputs.projectResourceId
output searchConnectionId string = !empty(searchServiceName) ? searchService.outputs.searchConnectionId : ''
