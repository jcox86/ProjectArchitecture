/*
module: infra.bicep.modules.containerAppsEnvironment
purpose: Provision an Azure Container Apps Managed Environment and wire app logs to Log Analytics.
exports:
  - outputs.managedEnvironmentId
  - outputs.managedEnvironmentDefaultDomain
patterns:
  - centralized_logging: all container apps emit logs/metrics to the same workspace
notes:
  - In the “simplest network baseline” this environment is public (no VNet integration).
*/

targetScope = 'resourceGroup'

param appName string
param environment string
param location string
param tags object

@description('Name override for the managed environment (optional).')
param managedEnvironmentName string = ''

@description('Log Analytics customer ID (workspace ID).')
param logAnalyticsCustomerId string

@secure()
@description('Log Analytics shared key (sensitive).')
param logAnalyticsSharedKey string

@description('Whether to enable zone redundancy (recommended for prod where supported).')
param zoneRedundant bool = (environment == 'prod')

var envName = (empty(managedEnvironmentName) ? 'aca-${appName}-${environment}' : managedEnvironmentName)

resource managedEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: envName
  location: location
  tags: tags
  properties: {
    zoneRedundant: zoneRedundant
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsCustomerId
        sharedKey: logAnalyticsSharedKey
      }
    }
  }
}

output managedEnvironmentId string = managedEnv.id
output managedEnvironmentDefaultDomain string = managedEnv.properties.defaultDomain

