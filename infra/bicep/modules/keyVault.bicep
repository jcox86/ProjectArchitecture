/*
module: infra.bicep.modules.keyVault
purpose: Provision an Azure Key Vault (RBAC-enabled) for secrets/certificates used by the platform.
exports:
  - outputs.keyVaultId
  - outputs.keyVaultName
  - outputs.keyVaultUri
patterns:
  - rbac_over_policies: use Azure RBAC rather than legacy access policies
notes:
  - Purge protection is recommended for prod.
*/

targetScope = 'resourceGroup'

param keyVaultName string
param location string
param tags object

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    enablePurgeProtection: true
    softDeleteRetentionInDays: 90
    sku: {
      family: 'A'
      name: 'standard'
    }
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

output keyVaultId string = kv.id
output keyVaultName string = kv.name
output keyVaultUri string = kv.properties.vaultUri

