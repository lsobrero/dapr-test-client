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

@description('The name of the service for the http-client service. The name is use as Dapr App ID.')
param httpClientServiceName string

@description('The target and dapr port for the http-client service.')
param httpClientPortNumber int

// Container Registry & Image
@description('The name of the container registry.')
param containerRegistryName string

@description('The resource ID of the user assigned managed identity for the container registry to be able to pull images from it.')
param containerUserAssignedManagedIdentityId string


@description('Use actors in traffic control service')
param useActors bool


// ------------------
// MODULES
// ------------------

module buildHttpClient 'br/public:deployment-scripts/build-acr:2.0.1' = {
  name: httpClientServiceName
  params: {
    AcrName: containerRegistryName
    location: location
    gitRepositoryUrl:  'https://github.com/mbn-ms-dk/DaprTrafficControl.git'
    dockerfileDirectory: 'TrafficControlService'
    imageName: 'dtc/trafficcontrol'
    imageTag: 'latest'
    cleanupPreference: 'Always'
  }
}

// ------------------
// RESOURCES
// ------------------

resource httpClientService 'Microsoft.App/containerApps@2023-05-01' = {
  name: httpClientServiceName
  location: location
  tags: union(tags, { containerApp: httpClientServiceName })
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
        external: true
        targetPort: httpClientPortNumber
        transport: 'auto'
        allowInsecure: true
      }
      dapr: {
        enabled: true
        appId: httpClientServiceName
        appProtocol: 'http'
        appPort: httpClientPortNumber
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
/*
sbrllbacr01.azurecr.io/dapr-test-client:21a6582324e57e5a3d48f24a77360ea0d0727d8a
*/
    template: {
      containers: [
        {
          name: httpClientServiceName
          image: 'dapr-test-client:21a6582324e57e5a3d48f24a77360ea0d0727d8a'
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
output httpClientServiceContainerAppName string = httpClientService.name
