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

// Service Bus
@description('The name of the service bus namespace.')
param serviceBusName string

@description('The name of the service bus topic.')
param serviceBusTopicName string

// Cosmos DB
@description('The name of the provisioned Cosmos DB resource.')
param cosmosDbName string 

@description('The name of the provisioned Cosmos DB\'s database.')
param cosmosDbDatabaseName string

@description('The name of Cosmos DB\'s collection.')
param cosmosDbCollectionName string

@secure()
@description('The Application Insights Instrumentation.')
param appInsightsInstrumentationKey string

@description('Application Insights secret name')
param applicationInsightsSecretName string


@description('Use actors in traffic control service')
param useActors bool

@description('Data actions permitted by the Role Definition')
param dataActions array = [
  'Microsoft.DocumentDB/databaseAccounts/readMetadata'
  'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
]


var roleDefinitionId = guid('sql-role-definition-', httpClientService.id)
var roleDefinitionName = 'My Read Write Role'
var roleAssignmentId = guid(roleDefinitionId, httpClientService.id)


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
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: serviceBusName
}

resource serviceBusTopic 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' existing = {
  name: serviceBusTopicName
  parent: serviceBusNamespace
}

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' existing = {
  name: cosmosDbName
}

resource cosmosDbDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' existing = {
  name: cosmosDbDatabaseName
  parent: cosmosDbAccount
}

resource cosmosDbDatabaseCollection 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' existing = {
  name: cosmosDbCollectionName
  parent: cosmosDbDatabase
}

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
        // exposedPort: trafficcontrolPortNumber
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
        {
          name: applicationInsightsSecretName
          value: appInsightsInstrumentationKey
        }
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
              name: 'ApplicationInsights__InstrumentationKey'
              secretRef: applicationInsightsSecretName
            }
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

// Assign cosmosdb account read/write access to aca system assigned identity
resource httpClientService_cosmosdb_role_assignment_system 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-09-15' = {
  name: guid(subscription().id, httpClientService.name, '00000000-0000-0000-0000-000000000002')
  parent: cosmosDbAccount
  properties: {
    principalId: httpClientService.identity.principalId
    roleDefinitionId:  resourceId('Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions', cosmosDbAccount.name, '00000000-0000-0000-0000-000000000002')//DocumentDB Data Contributor
    scope: '${cosmosDbAccount.id}/dbs/${cosmosDbDatabase.name}/colls/${cosmosDbDatabaseCollection.name}'
  }
}

resource sqlRoleDefinition 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2023-09-15' = {
  parent: cosmosDbAccount
  name: roleDefinitionId
  properties: {
    roleName: roleDefinitionName
    type: 'CustomRole'
    assignableScopes: [
      cosmosDbAccount.id
    ]
    permissions: [
      {
        dataActions: dataActions
      }
    ]
  }
}

resource sqlRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-04-15' = {
  parent: cosmosDbAccount
  name: roleAssignmentId
  properties: {
    roleDefinitionId: sqlRoleDefinition.id
    principalId: httpClientService.identity.principalId
    scope: cosmosDbAccount.id
  }
}

resource trafficcontrolService_sb_role_assignment_system 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, httpClientService.name, '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39')
  properties: {
    principalId: httpClientService.identity.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39')//Azure Service Bus Data Sender
    principalType: 'ServicePrincipal'
  }
  scope: serviceBusTopic
}
// ------------------
// OUTPUTS
// ------------------

@description('The name of the container app for the frontend web app service.')
output httpClientServiceContainerAppName string = httpClientService.name
