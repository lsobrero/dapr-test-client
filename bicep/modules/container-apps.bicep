targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = resourceGroup().location

@description('The tags to be assigned to the created resources.')
param tags object = {}

@description('The name of the container apps environment.')
param containerAppsEnvironmentName string

// Services
@description('The name of the service for the http-server service. The name is use as Dapr App ID.')
param httpServerServiceName string

@description('The name of the service for the http-client service. The name is use as Dapr App ID.')
param httpClientServiceName string

// Container Registry & Images
@description('The name of the container registry.')
param containerRegistryName string

// App Ports
@description('The dapr port for the http-server service.')
param httpServerPortNumber int

@description('The dapr port for the http-client service.')
param httpClientPortNumber int

@description('Use actors in traffic control service')
param useActors bool

// ------------------
// VARIABLES
// ------------------

var containerRegistryPullRoleGuid='7f951dda-4ed3-4680-a7ca-43fe172d538d'

// ------------------
// RESOURCES
// ------------------

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: containerAppsEnvironmentName
}
//Reference to AppInsights resource

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
}

resource containerUserAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'aca-user-identity-${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
}

resource containerRegistryPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if(!empty(containerRegistryName)) {
  name: guid(subscription().id, containerRegistry.id, containerUserAssignedManagedIdentity.id) 
  scope: containerRegistry
  properties: {
    principalId: containerUserAssignedManagedIdentity.properties.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', containerRegistryPullRoleGuid)
    principalType: 'ServicePrincipal'
  }
}


module httpClientService 'container-apps/http-client-service.bicep' = {
  name: 'httpClientService-${uniqueString(resourceGroup().id)}'
  params: {
    location: location
    tags: tags
    containerAppsEnvironmentId: containerAppsEnvironment.id
    httpClientServiceName: httpClientServiceName
    httpClientPortNumber: httpClientPortNumber
    containerRegistryName: containerRegistryName
    containerUserAssignedManagedIdentityId: containerUserAssignedManagedIdentity.id
    useActors: useActors
    
  }
}

module httpServerService 'container-apps/http-server-service.bicep' = {
  name: 'httpServerService-${uniqueString(resourceGroup().id)}'
  params: {
    httpServerServiceName: httpServerServiceName
    location: location
    tags: tags
    containerAppsEnvironmentId: containerAppsEnvironment.id
    appInsightsInstrumentationKey: applicationInsights.properties.InstrumentationKey
    applicationInsightsSecretName: applicationInsightsSecretName
    containerRegistryName: containerRegistryName
    containerUserAssignedManagedIdentityId: containerUserAssignedManagedIdentity.id
    httpServerPortNumber: httpServerPortNumber
    keyVaultName: keyVaultName
    serviceBusName: serviceBusName
  }
}





// ------------------
// OUTPUTS
// ------------------


@description('The name of the container app for the http-client service.')
output httpClientServiceContainerAppName string = httpClientService.name

@description('The name of the container app for the http-server service.')
output httpServerServiceContainerAppName string = httpServerService.name
