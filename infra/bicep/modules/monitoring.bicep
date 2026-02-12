/*
module: infra.bicep.modules.monitoring
purpose: Provision monitoring primitives: Log Analytics workspace + Application Insights (workspace-based).
exports:
  - outputs.logAnalyticsWorkspaceId
  - outputs.logAnalyticsCustomerId
  - outputs.logAnalyticsPrimarySharedKey (sensitive, for ACA env logs wiring)
  - outputs.appInsightsId
  - outputs.appInsightsConnectionString
patterns:
  - workspace_based_appinsights: AI connected to LA for centralized queries
notes:
  - Treat shared keys/connection strings as secrets; do not print in CI logs.
*/

targetScope = 'resourceGroup'

param appName string
param environment string
param location string
param tags object

@description('Log Analytics retention in days.')
param logAnalyticsRetentionInDays int = 30

@description('Application Insights name override (optional).')
param appInsightsName string = ''

@description('Log Analytics workspace name override (optional).')
param logAnalyticsWorkspaceName string = ''

var laName = (empty(logAnalyticsWorkspaceName) ? 'la-${appName}-${environment}' : logAnalyticsWorkspaceName)
var aiName = (empty(appInsightsName) ? 'appi-${appName}-${environment}' : appInsightsName)

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: laName
  location: location
  tags: tags
  properties: {
    retentionInDays: logAnalyticsRetentionInDays
    sku: {
      name: 'PerGB2018'
    }
  }
}

// Workspace-based App Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: aiName
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

// Shared key for wiring Container Apps Environment logs.
output logAnalyticsWorkspaceId string = logAnalytics.id
output logAnalyticsCustomerId string = logAnalytics.properties.customerId
@secure()
output logAnalyticsPrimarySharedKey string = logAnalytics.listKeys().primarySharedKey

output appInsightsId string = appInsights.id
output appInsightsConnectionString string = appInsights.properties.ConnectionString

