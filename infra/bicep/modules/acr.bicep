/*
module: infra.bicep.modules.acr
purpose: Provision Azure Container Registry for hosting API/Worker/AdminUi images.
exports:
  - outputs.acrId
  - outputs.acrLoginServer
patterns:
  - managed_identity_pull: container apps use AcrPull RBAC instead of registry passwords
notes:
  - Admin user is disabled by default (best practice).
*/

targetScope = 'resourceGroup'

param acrName string
param location string
param tags object

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSku string = 'Standard'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 7
        status: 'disabled'
      }
    }
  }
}

output acrId string = acr.id
output acrLoginServer string = acr.properties.loginServer

