targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The name of the container apps environment.')
param containerAppsEnvironmentName string

@description('The name of the service for the http-server service. The name is used as Dapr App ID.')
param httpServerServiceName string

@description('The name of the service for the http-client service. The name is used as Dapr App ID and as the name of service bus topic subscription.')
param httpClientServiceName string


// ------------------
// RESOURCES
// ------------------

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: containerAppsEnvironmentName
}
