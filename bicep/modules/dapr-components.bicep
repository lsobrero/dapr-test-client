targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The name of the container apps environment.')
param containerAppsEnvironmentName string

@description('The name of the service bus namespace.')
param serviceBusName string

@description('The name of Cosmos DB resource.')
param cosmosDbName string

@description('The name of Cosmos DB\'s database.')
param cosmosDbDatabaseName string

@description('The name of Cosmos DB\'s collection.')
param cosmosDbCollectionName string

@description('The name of Dapr component for the secret store building block.')
// We disable lint of this line as it is not a secret but the name of the Dapr component
#disable-next-line secure-secrets-in-params
param secretStoreComponentName string

@description('The name of the key vault resource.')
param keyVaultName string

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

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2023-09-15' existing = {
  name: cosmosDbName
}

//Secret Store Component
resource secretstoreComponent 'Microsoft.App/managedEnvironments/daprComponents@2023-05-01' = {
  name: secretStoreComponentName
  parent: containerAppsEnvironment
  properties: {
    componentType: 'secretstores.azure.keyvault'
    version: 'v1'
    metadata: [
      {
        name: 'vaultName'
        value: keyVaultName
      }
    ]
    scopes: [
      httpServerServiceName
      httpClientServiceName
    ]
  }
}

//Cosmos DB State Store Component
resource statestoreComponent 'Microsoft.App/managedEnvironments/daprComponents@2023-05-01' = {
  name: 'statestore'
  parent: containerAppsEnvironment
  properties: {
    componentType: 'state.azure.cosmosdb'
    version: 'v1'
    secrets: [
    ]
    metadata: [
      {
        name: 'url'
        value: cosmosDbAccount.properties.documentEndpoint
      }
      {
        name: 'database'
        value: cosmosDbDatabaseName
      }
      {
        name: 'collection'
        value: cosmosDbCollectionName
      }
      {
        name: 'actorStateStore'
        value: 'true'
      }
    ]
    scopes: [
      httpClientServiceName
      httpServerServiceName
    ]
  }
}

//PubSub service bus Component
resource pubsubComponent 'Microsoft.App/managedEnvironments/daprComponents@2023-05-01' = {
  name: 'pubsub'
  parent: containerAppsEnvironment
  properties: {
    componentType: 'pubsub.azure.servicebus'
    version: 'v1'
    secrets: [
    ]
    metadata: [
      {
        name: 'namespaceName'
        value: '${serviceBusName}.servicebus.windows.net'
      }
      {
        name: 'consumerID'
        value: httpServerServiceName
      }
    ]
    scopes: [
      httpClientServiceName
      httpServerServiceName
    ]
  }
}

