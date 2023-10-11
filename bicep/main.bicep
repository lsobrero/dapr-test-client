targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = resourceGroup().location

@description('Optional. The prefix to be used for all resources created by this template.')
param prefix string = ''

@description('Optional. The suffix to be used for all resources created by this template.')
param suffix string = ''

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {
  solution: 'http-client-server'
  shortName: 'hcs'
  iac: 'bicep'
  environment: 'aca'
}

@description('Optional. The name of the azure container resource')
param containerRegistryName string

// Container Apps Env / Log Analytics Workspace / Application Insights
@description('Optional. The name of the container apps environment. If set, it overrides the name generated by the template.')
param containerAppsEnvironmentName string = '${prefix}cae-${uniqueString(resourceGroup().id)}${suffix}'

@description('Optional. The name of the log analytics workspace. If set, it overrides the name generated by the template.')
param logAnalyticsWorkspaceName string = '${prefix}log-${uniqueString(resourceGroup().id)}${suffix}'

@description('Optional. The name of the application insights. If set, it overrides the name generated by the template.')
param applicationInsightName string = '${prefix}appi-${uniqueString(resourceGroup().id)}${suffix}'

// Dapr
@description('The name of Dapr component for the secret store building block.')
// We disable lint of this line as it is not a secret but the name of the Dapr component
#disable-next-line secure-secrets-in-params
param secretStoreComponentName string

// Services

@description('The name of the service for the http-server service. The name is use as Dapr App ID and as the name of service bus topic subscription.')
param httpServerServiceName string

@description('The name of the service for the http-client service. The name is use as Dapr App ID.')
param httpClientServiceName string


// App Ports

@description('The dapr port for the http-server service.')
param httpServerPortNumber int = 8081

@description('The dapr port for the http-client service.')
param httpClientPortNumber int = 8080

@description('Use actors flag')
param useActors bool = false


// ------------------
// RESOURCES
// ------------------

module containerAppsEnvironment 'modules/container-apps-environment.bicep' ={
  name: 'containerAppsEnv-${uniqueString(resourceGroup().id)}'
  params: {
   containerAppsEnvironmentName: containerAppsEnvironmentName
   logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
   applicationInsightName: applicationInsightName
    location: location
    tags: tags
  }
}



module daprComponents 'modules/dapr-components.bicep' = {
  name: 'daprComponents-${uniqueString(resourceGroup().id)}'
  params: {
    containerAppsEnvironmentName: containerAppsEnvironmentName    
    httpServerServiceName: httpServerServiceName
    httpClientServiceName: httpClientServiceName
  }
  dependsOn: [
    containerAppsEnvironment
  ]
}

module acr 'modules/container-registry.bicep' = {
  name: 'acr-${uniqueString(resourceGroup().id)}'
  params: {
    acrName: 'acr${uniqueString(resourceGroup().id)}'
    location: location
    tags: tags
  }
}

module containerApps 'modules/container-apps.bicep' = {
  name: 'containerApps-${uniqueString(resourceGroup().id)}'
  params: {
    location: location
    tags: tags
    httpServerServiceName: httpServerServiceName
    httpClientServiceName: httpClientServiceName
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    httpServerPortNumber: httpServerPortNumber
    httpClientPortNumber: httpClientPortNumber
    useActors: useActors
  }
  /*dependsOn: [
    daprComponents
  ]*/
}


// ------------------
// OUTPUTS
// ------------------

@description('The name of the container app for the http-client service.')
output trafficcontrolServiceContainerAppName string = containerApps.outputs.httpClientServiceContainerAppName

@description('The name of the container app for the http-server service.')
output finecollectionServiceContainerAppName string = containerApps.outputs.httpServerServiceContainerAppName

