@description('Primary location for all resources')
param location string

@description('Tags that will be applied to all resources')
param tags object = {}

@description('Resource name for the container registry')
param acrResourceName string

module containerRegistry 'br/public:avm/res/container-registry/registry:0.1.1' = {
  name: 'registry'
  params: {
    name: acrResourceName
    location: location
    tags: tags
    publicNetworkAccess: 'Enabled'
  }
}


/*
// Create the ACR connection using the centralized connection module
module acrConnection '../connection.bicep' = {
  name: 'acr-connection-creation'
  params: {
    aiServicesAccountName: aiServicesAccountName
    aiProjectName: aiProjectName
    connectionConfig: {
      name: connectionName
      category: 'ContainerRegistry'
      target: containerRegistry.outputs.loginServer
      authType: 'ManagedIdentity'
      credentials: {
        clientId: aiAccount::aiProject.identity.principalId
        resourceId: containerRegistry.outputs.resourceId
      }
      isSharedToAll: true
      metadata: {
        ResourceId: containerRegistry.outputs.resourceId
      }
    }
  }
}
*/

output containerRegistryName string = containerRegistry.outputs.name
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer
output containerRegistryResourceId string = containerRegistry.outputs.resourceId
//output containerRegistryConnectionName string = acrConnection.outputs.connectionName
