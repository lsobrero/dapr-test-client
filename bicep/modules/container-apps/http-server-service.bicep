targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = resourceGroup().location

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

@description('The resource Id of the container apps environment.')
param containerAppsEnvironmentId string

@description('The name of the service for the http-server service. The name is use as Dapr App ID.')
param httpServerServiceName string

@description('The target and dapr port for the http-server service.')
param httpServerPortNumber int

// Container Registry & Image
@description('The name of the container registry.')
param containerRegistryName string

@description('The resource ID of the user assigned managed identity for the container registry to be able to pull images from it.')
param containerUserAssignedManagedIdentityId string


// ------------------
// MODULES
// ------------------

module buildHttpServer 'br/public:deployment-scripts/build-acr:2.0.1' = {
  name: httpServerServiceName
  params: {
    AcrName: containerRegistryName
    location: location
    gitRepositoryUrl:  'https://github.com/mbn-ms-dk/DaprTrafficControl.git'
    dockerfileDirectory: 'FineCollectionService'
    imageName: 'dtc/finecollection'
    imageTag: 'latest'
    cleanupPreference: 'Always'
  }
}

// ------------------
// RESOURCES
// ------------------

  
resource httpServerService 'Microsoft.App/containerApps@2023-05-01' = {
  name: httpServerServiceName
  location: location
  tags: union(tags, { containerApp: httpServerServiceName })
  identity: {
    type: 'SystemAssigned,UserAssigned'
    userAssignedIdentities: {
        '${containerUserAssignedManagedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        external: false
        targetPort: httpServerPortNumber
      }
      dapr: {
        enabled: true
        appId: httpServerServiceName
        appProtocol: 'http'
        appPort: httpServerPortNumber
        logLevel: 'info'
        enableApiLogging: true
      }
      secrets: [
      ]
      registries: !empty(containerRegistryName) ? [
        {
          server: '${containerRegistryName}.azurecr.io'
          identity: containerUserAssignedManagedIdentityId
        }
      ] : []
    }
    template: {
      containers: [
        {
          name: httpServerServiceName
          image: buildHttpServer.outputs.acrImage
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          env: [
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}


// ------------------
// OUTPUTS
// ------------------

@description('The name of the container app for the frontend web app service.')
output httpServerServiceContainerAppName string = httpServerService.name
