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

param containerRegistryUsername string

@secure()
param containerRegistryPassword string
param secrets array = [
  {
    name: 'acr-password'
    value: containerRegistryPassword
  }
]
var registrySecretRefName = 'acr-password'

param containerImage string

@description('Use actors in traffic control service')
param useActors bool


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
      secrets: secrets
      registries: !empty(containerRegistryName) ? [
        {
          server: containerRegistryName
          username: containerRegistryUsername
          passwordSecretRef: registrySecretRefName
        }
      ] : []
    }
    template: {
      containers: [
        {
          name: httpServerServiceName
          image: 'sbrllbacr01.azurecr.io/dapr-test-server:711e9498569f61f22b2c66d1e72fe7817f7fc51c'
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          env: [
            {
              name: 'USE_ACTORS'
              value: '${useActors}'
            }
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
