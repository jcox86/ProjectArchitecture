/*
module: infra.bicep.mainSubscription
purpose: Optional subscription-scoped bootstrap entrypoint. Creates the environment Resource Group and applies baseline locks/RBAC.
exports:
  - resourceGroupId: ID of the created resource group
patterns:
  - bootstrap_then_deploy: create RG/locks here, then run `main.rg.bicep` at RG scope
notes:
  - This is optional; teams can create RGs out-of-band and only use `main.rg.bicep`.
*/

targetScope = 'subscription'

@description('Short application name used in resource names (e.g., "saastpl").')
param appName string

@description('Deployment environment name (dev/staging/prod).')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string

@description('Azure region (location) for the Resource Group.')
param location string

@description('Resource Group name. If empty, computed as rg-<app>-<env>-<region>.')
param resourceGroupName string = 'rg-${appName}-${environment}-${toLower(replace(location, ' ', ''))}'

@description('Whether to apply a CanNotDelete lock to the Resource Group (recommended for prod).')
param applyDeleteLock bool = (environment == 'prod')

resource rg 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: resourceGroupName
  location: location
  tags: {
    app: appName
    env: environment
  }
}

resource lockRg 'Microsoft.Authorization/locks@2020-05-01' = if (applyDeleteLock) {
  name: 'lock-${resourceGroupName}-cannotdelete'
  scope: rg
  properties: {
    level: 'CanNotDelete'
    notes: 'Protect environment RG from accidental deletion. Disable only with explicit approval.'
  }
}

output resourceGroupName string = rg.name
output resourceGroupId string = rg.id

