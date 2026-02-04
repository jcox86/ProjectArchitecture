/*
module: infra.bicep.modules.appConfig
purpose: Provision Azure App Configuration for non-secret runtime configuration (global, not per-tenant).
exports:
  - outputs.appConfigId
  - outputs.appConfigEndpoint
patterns:
  - aad_auth_only: disable local auth; use RBAC for access
notes:
  - Keep per-tenant feature flags in Catalog DB (per earlier decision); App Config is for global config.
*/

targetScope = 'resourceGroup'

param appConfigName string
param location string
param tags object

@allowed([
  'Free'
  'Standard'
])
param skuName string = 'Standard'

resource appConfig 'Microsoft.AppConfiguration/configurationStores@2023-03-01' = {
  name: appConfigName
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  properties: {
    disableLocalAuth: true
    publicNetworkAccess: 'Enabled'
  }
}

output appConfigId string = appConfig.id
output appConfigEndpoint string = appConfig.properties.endpoint

