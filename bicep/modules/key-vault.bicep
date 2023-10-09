targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = resourceGroup().location

@description('The name of the Key Vault. If set, it overrides the name generated by the template.')
param keyVaultName string

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

// ------------------
// RESOURCES
// ------------------
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location  
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableSoftDelete: false
    softDeleteRetentionInDays: 7
    enablePurgeProtection: null  // It seems that you cannot set it to False even the first time. workaround is not to set it at all: https://github.com/Azure/bicep/issues/5223
    enableRbacAuthorization: true
    enabledForTemplateDeployment: true
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The resource ID of the key vault.')
output keyVaultId string = keyVault.id
