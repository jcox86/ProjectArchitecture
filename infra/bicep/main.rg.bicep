/*
module: infra.bicep.mainRg
purpose: Resource-group scoped deployment entrypoint. Composes all Azure resources for one environment (dev/staging/prod).
exports:
  - outputs: resource IDs/URIs/FQDNs used by app deployment pipelines
patterns:
  - composition_root: only wire modules here; keep resources inside `modules/`
  - explicit_outputs: expose only what downstream pipelines need
notes:
  - Designed to be idempotent; safe to re-run.
  - Front Door tier is parameterized (Standard/Premium).
*/

targetScope = 'resourceGroup'

@description('Short application name used in resource names (e.g., "saastpl").')
param appName string

@description('Deployment environment name (dev/staging/prod).')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string

@description('Azure region (location) for regional resources.')
param location string

@description('DNS root domain (e.g., "app.com"). Used for Front Door custom domains: admin.<root> and *.<root>.')
param dnsRoot string

@description('Azure Front Door tier. Premium enables managed WAF rules + bot protection and Private Link origins options.')
@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param frontDoorSkuName string = (environment == 'prod' ? 'Premium_AzureFrontDoor' : 'Standard_AzureFrontDoor')

@description('PostgreSQL admin login name (non-secret). Password should be provided via Key Vault/secret references, not as a param here.')
param postgresAdminLogin string = 'pgadmin'

@secure()
@description('PostgreSQL admin password (secret). Provide via CI/CD secrets; do not commit in param files.')
param postgresAdminPassword string

@description('PostgreSQL runtime login used by application services (API/Worker). This user is created by DB migrations.')
param postgresAppLogin string = 'appuser'

@secure()
@description('PostgreSQL runtime password for application services (API/Worker). Stored in Key Vault and referenced by Container Apps.')
param postgresAppPassword string = postgresAdminPassword

@description('PostgreSQL server name (computed if empty).')
param postgresServerName string = 'psql-${appName}-${environment}'

@description('Redis cache name (computed if empty).')
param redisName string = 'redis-${appName}-${environment}'

@description('API autoscaling: concurrent HTTP requests per replica (HTTP scaler).')
param apiHttpConcurrentRequests int = (environment == 'prod' ? 50 : 25)

@description('Admin UI autoscaling: concurrent HTTP requests per replica (HTTP scaler).')
param adminUiHttpConcurrentRequests int = (environment == 'prod' ? 100 : 50)

@description('Worker autoscaling: scale out when a queue exceeds this length (per replica).')
param workerQueueLength int = (environment == 'prod' ? 50 : 10)

@description('Enable Worker queue-based autoscaling (KEDA Azure Storage Queue).')
param enableWorkerQueueScaling bool = true

@description('Storage account name (must be globally unique; provide per-environment).')
param storageAccountName string

@description('Key Vault name (must be globally unique; provide per-environment).')
param keyVaultName string

@description('ACR name (must be globally unique; provide per-environment).')
param acrName string

@description('App Configuration name (must be globally unique; provide per-environment).')
param appConfigName string

@description('Enable Front Door custom domains (admin.<root> and *.<root>) with customer-managed wildcard certificate from Key Vault.')
param enableFrontDoorCustomDomains bool = false

@description('Key Vault secret name for the wildcard certificate (required if enableFrontDoorCustomDomains).')
param wildcardCertificateSecretName string = ''

@description('Key Vault secret version for the wildcard certificate (optional). Empty uses latest.')
param wildcardCertificateSecretVersion string = ''

@description('Default container image for API until app pipeline deploys real image.')
param apiImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('Default container image for Worker until app pipeline deploys real image.')
param workerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('Default container image for Admin UI until app pipeline deploys real image.')
param adminUiImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

var tags = {
  app: appName
  env: environment
}

// Foundation
module kv 'modules/keyVault.bicep' = {
  name: 'keyVault'
  params: {
    keyVaultName: keyVaultName
    location: location
    tags: tags
    enablePurgeProtection: (environment == 'prod')
  }
}

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    appName: appName
    environment: environment
    location: location
    tags: tags
  }
}

module acaEnv 'modules/containerAppsEnvironment.bicep' = {
  name: 'containerAppsEnvironment'
  params: {
    appName: appName
    environment: environment
    location: location
    tags: tags
    logAnalyticsCustomerId: monitoring.outputs.logAnalyticsCustomerId
    logAnalyticsSharedKey: monitoring.outputs.logAnalyticsPrimarySharedKey
    zoneRedundant: (environment == 'prod')
  }
}

module acr 'modules/acr.bicep' = {
  name: 'acr'
  params: {
    acrName: acrName
    location: location
    tags: tags
    acrSku: (environment == 'prod' ? 'Premium' : 'Standard')
  }
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    storageAccountName: storageAccountName
    location: location
    tags: tags
    skuName: (environment == 'prod' ? 'Standard_ZRS' : 'Standard_LRS')
  }
}

module redis 'modules/redis.bicep' = {
  name: 'redis'
  params: {
    redisName: redisName
    location: location
    tags: tags
    skuName: (environment == 'prod' ? 'Premium' : 'Standard')
    skuCapacity: (environment == 'prod' ? 2 : 1)
  }
}

module appConfig 'modules/appConfig.bicep' = {
  name: 'appConfig'
  params: {
    appConfigName: appConfigName
    location: location
    tags: tags
    skuName: (environment == 'prod' ? 'Standard' : 'Standard')
  }
}

module postgres 'modules/postgresFlexibleServer.bicep' = {
  name: 'postgres'
  params: {
    serverName: postgresServerName
    location: location
    tags: tags
    administratorLogin: postgresAdminLogin
    administratorLoginPassword: postgresAdminPassword
    haMode: (environment == 'prod' ? 'ZoneRedundant' : 'Disabled')
    allowAzureServices: true
  }
}

// Runtime wiring: Key Vault secret URLs (latest version).
var kvSecretUrlPostgresAdminPassword = '${kv.outputs.keyVaultUri}secrets/postgres-admin-password'
var kvSecretUrlPostgresAppPassword = '${kv.outputs.keyVaultUri}secrets/postgres-app-password'
var kvSecretUrlRedisPrimaryKey = '${kv.outputs.keyVaultUri}secrets/redis-primary-key'
var kvSecretUrlStorageConnectionString = '${kv.outputs.keyVaultUri}secrets/storage-connection-string'
var kvSecretUrlAppInsightsConnectionString = '${kv.outputs.keyVaultUri}secrets/appinsights-connection-string'

// Shared non-secret environment variables for API/Worker.
var commonRuntimeEnv = [
  {
    name: 'AppConfig__Endpoint'
    value: appConfig.outputs.appConfigEndpoint
  }
  {
    name: 'KeyVault__Uri'
    value: kv.outputs.keyVaultUri
  }
  {
    name: 'Postgres__Host'
    value: postgres.outputs.serverFqdn
  }
  {
    name: 'Postgres__Username'
    value: postgresAppLogin
  }
  {
    name: 'Postgres__CatalogDb'
    value: 'catalog'
  }
  {
    name: 'Postgres__TenantSharedDb'
    value: 'tenant_shared'
  }
  {
    name: 'Redis__Host'
    value: redis.outputs.redisHostName
  }
  {
    name: 'Redis__Port'
    value: string(redis.outputs.redisSslPort)
  }
  {
    name: 'Storage__AccountName'
    value: storageAccountName
  }
  {
    name: 'Storage__Queues__Work'
    value: 'work'
  }
  {
    name: 'Storage__Queues__WorkPoison'
    value: 'work-poison'
  }
  {
    name: 'Storage__Queues__Outbox'
    value: 'outbox'
  }
  {
    name: 'Storage__Queues__OutboxPoison'
    value: 'outbox-poison'
  }
  {
    name: 'Storage__Containers__Attachments'
    value: 'attachments'
  }
]

// Container App secrets (Key Vault-backed).
var commonRuntimeSecrets = [
  {
    name: 'postgres-app-password'
    keyVaultUrl: kvSecretUrlPostgresAppPassword
    identity: 'system'
  }
  {
    name: 'redis-primary-key'
    keyVaultUrl: kvSecretUrlRedisPrimaryKey
    identity: 'system'
  }
  {
    name: 'appinsights-connection-string'
    keyVaultUrl: kvSecretUrlAppInsightsConnectionString
    identity: 'system'
  }
]

var apiRuntimeEnv = concat(commonRuntimeEnv, [
  {
    name: 'Postgres__Password'
    secretRef: 'postgres-app-password'
  }
  {
    name: 'Redis__Password'
    secretRef: 'redis-primary-key'
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    secretRef: 'appinsights-connection-string'
  }
])

var workerRuntimeEnv = apiRuntimeEnv

var workerScaleRules = [
  {
    name: 'work-queue'
    custom: {
      type: 'azure-storage-queue'
      metadata: {
        queueName: 'work'
        queueLength: string(workerQueueLength)
        accountName: storageAccountName
      }
      auth: [
        {
          secretRef: 'storage-connection-string'
          triggerParameter: 'connection'
        }
      ]
    }
  }
  {
    name: 'outbox-queue'
    custom: {
      type: 'azure-storage-queue'
      metadata: {
        queueName: 'outbox'
        queueLength: string(workerQueueLength)
        accountName: storageAccountName
      }
      auth: [
        {
          secretRef: 'storage-connection-string'
          triggerParameter: 'connection'
        }
      ]
    }
  }
]

// Apps (placeholder images; real images deployed by app pipeline)
module apiApp 'modules/containerApp.api.bicep' = {
  name: 'apiApp'
  dependsOn: [
    secretPostgresAppPassword
    secretRedisPrimaryKey
    secretAppInsightsConnectionString
  ]
  params: {
    name: apiContainerAppName
    location: location
    tags: tags
    managedEnvironmentId: acaEnv.outputs.managedEnvironmentId
    image: apiImage
    secrets: commonRuntimeSecrets
    env: apiRuntimeEnv
    targetPort: 8080
    minReplicas: (environment == 'prod' ? 2 : 1)
    maxReplicas: 10
    httpConcurrentRequests: apiHttpConcurrentRequests
    acrLoginServer: acr.outputs.acrLoginServer
  }
}

module workerApp 'modules/containerApp.worker.bicep' = {
  name: 'workerApp'
  dependsOn: [
    secretPostgresAppPassword
    secretRedisPrimaryKey
    secretStorageConnectionString
    secretAppInsightsConnectionString
  ]
  params: {
    name: workerContainerAppName
    location: location
    tags: tags
    managedEnvironmentId: acaEnv.outputs.managedEnvironmentId
    image: workerImage
    secrets: concat(commonRuntimeSecrets, [
      {
        name: 'storage-connection-string'
        keyVaultUrl: kvSecretUrlStorageConnectionString
        identity: 'system'
      }
    ])
    env: workerRuntimeEnv
    minReplicas: 1
    maxReplicas: 5
    scaleRules: enableWorkerQueueScaling ? workerScaleRules : []
    acrLoginServer: acr.outputs.acrLoginServer
  }
}

module adminUiApp 'modules/containerApp.adminui.bicep' = {
  name: 'adminUiApp'
  params: {
    name: adminUiContainerAppName
    location: location
    tags: tags
    managedEnvironmentId: acaEnv.outputs.managedEnvironmentId
    image: adminUiImage
    env: [
      // Default to same-origin API path via Front Door route: admin.<root>/api/*
      {
        name: 'AdminUi__ApiBasePath'
        value: '/api'
      }
    ]
    targetPort: 80
    minReplicas: 1
    maxReplicas: 5
    httpConcurrentRequests: adminUiHttpConcurrentRequests
    acrLoginServer: acr.outputs.acrLoginServer
  }
}

// RBAC: allow container apps to pull from ACR and access dependencies via managed identity.
resource acrRes 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

resource kvRes 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource stRes 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource appConfigRes 'Microsoft.AppConfiguration/configurationStores@2023-03-01' existing = {
  name: appConfigName
}

resource redisRes 'Microsoft.Cache/Redis@2023-08-01' existing = {
  name: redisName
}

// Store runtime secrets in Key Vault (used by ACA keyVaultUrl secrets).
var storageKeys = listKeys(stRes.id, stRes.apiVersion)
var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storageKeys.keys[0].value};EndpointSuffix=${environment().suffixes.storage}'

var redisKeys = listKeys(redisRes.id, redisRes.apiVersion)

resource secretPostgresAdminPassword 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kvRes
  name: 'postgres-admin-password'
  properties: {
    value: postgresAdminPassword
  }
  dependsOn: [
    kv
  ]
}

resource secretPostgresAppPassword 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kvRes
  name: 'postgres-app-password'
  properties: {
    value: postgresAppPassword
  }
  dependsOn: [
    kv
  ]
}

resource secretRedisPrimaryKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kvRes
  name: 'redis-primary-key'
  properties: {
    value: redisKeys.primaryKey
  }
  dependsOn: [
    kv
    redis
  ]
}

resource secretStorageConnectionString 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kvRes
  name: 'storage-connection-string'
  properties: {
    value: storageConnectionString
  }
  dependsOn: [
    kv
    storage
  ]
}

resource secretAppInsightsConnectionString 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kvRes
  name: 'appinsights-connection-string'
  properties: {
    value: monitoring.outputs.appInsightsConnectionString
  }
  dependsOn: [
    kv
    monitoring
  ]
}

var roleAcrPull = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
var roleKvSecretsUser = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
var roleStorageBlobDataContributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
var roleStorageQueueDataContributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '974c5e8b-45b9-4653-ba55-5f855dd0fb88')
var roleAppConfigDataReader = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '516239f1-63e1-4d78-a4de-a74fb236a071')

var apiContainerAppName = '${appName}-api-${environment}'
var workerContainerAppName = '${appName}-worker-${environment}'
var adminUiContainerAppName = '${appName}-adminui-${environment}'

resource acrPullApi 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrRes.id, apiContainerAppName, 'acrpull')
  scope: acrRes
  properties: {
    principalId: apiApp.outputs.principalId
    roleDefinitionId: roleAcrPull
    principalType: 'ServicePrincipal'
  }
}

resource acrPullWorker 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrRes.id, workerContainerAppName, 'acrpull')
  scope: acrRes
  properties: {
    principalId: workerApp.outputs.principalId
    roleDefinitionId: roleAcrPull
    principalType: 'ServicePrincipal'
  }
}

resource acrPullAdminUi 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrRes.id, adminUiContainerAppName, 'acrpull')
  scope: acrRes
  properties: {
    principalId: adminUiApp.outputs.principalId
    roleDefinitionId: roleAcrPull
    principalType: 'ServicePrincipal'
  }
}

resource kvSecretsUserApi 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kvRes.id, apiContainerAppName, 'kvsecretsuser')
  scope: kvRes
  properties: {
    principalId: apiApp.outputs.principalId
    roleDefinitionId: roleKvSecretsUser
    principalType: 'ServicePrincipal'
  }
}

resource kvSecretsUserWorker 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kvRes.id, workerContainerAppName, 'kvsecretsuser')
  scope: kvRes
  properties: {
    principalId: workerApp.outputs.principalId
    roleDefinitionId: roleKvSecretsUser
    principalType: 'ServicePrincipal'
  }
}

resource blobContributorApi 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(stRes.id, apiContainerAppName, 'blobcontrib')
  scope: stRes
  properties: {
    principalId: apiApp.outputs.principalId
    roleDefinitionId: roleStorageBlobDataContributor
    principalType: 'ServicePrincipal'
  }
}

resource blobContributorWorker 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(stRes.id, workerContainerAppName, 'blobcontrib')
  scope: stRes
  properties: {
    principalId: workerApp.outputs.principalId
    roleDefinitionId: roleStorageBlobDataContributor
    principalType: 'ServicePrincipal'
  }
}

resource queueContributorApi 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(stRes.id, apiContainerAppName, 'queuecontrib')
  scope: stRes
  properties: {
    principalId: apiApp.outputs.principalId
    roleDefinitionId: roleStorageQueueDataContributor
    principalType: 'ServicePrincipal'
  }
}

resource queueContributorWorker 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(stRes.id, workerContainerAppName, 'queuecontrib')
  scope: stRes
  properties: {
    principalId: workerApp.outputs.principalId
    roleDefinitionId: roleStorageQueueDataContributor
    principalType: 'ServicePrincipal'
  }
}

resource appConfigReaderApi 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(appConfigRes.id, apiContainerAppName, 'appconfigread')
  scope: appConfigRes
  properties: {
    principalId: apiApp.outputs.principalId
    roleDefinitionId: roleAppConfigDataReader
    principalType: 'ServicePrincipal'
  }
}

resource appConfigReaderWorker 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(appConfigRes.id, workerContainerAppName, 'appconfigread')
  scope: appConfigRes
  properties: {
    principalId: workerApp.outputs.principalId
    roleDefinitionId: roleAppConfigDataReader
    principalType: 'ServicePrincipal'
  }
}

// Edge (Front Door)
var frontDoorEndpointName = toLower('afd-${appName}-${environment}-${uniqueString(resourceGroup().id)}')

module afd 'modules/frontDoor.standardPremium.bicep' = {
  name: 'frontDoor'
  params: {
    appName: appName
    environment: environment
    skuName: frontDoorSkuName
    endpointName: frontDoorEndpointName
    originHostNameApi: apiApp.outputs.ingressFqdn
    originHostNameAdminUi: adminUiApp.outputs.ingressFqdn
    enableCustomDomains: enableFrontDoorCustomDomains
    dnsRoot: dnsRoot
    certificateKeyVaultName: keyVaultName
    certificateKeyVaultSecretName: wildcardCertificateSecretName
    certificateKeyVaultSecretVersion: wildcardCertificateSecretVersion
  }
}

output infraTags object = tags

output keyVaultUri string = kv.outputs.keyVaultUri
output acrLoginServer string = acr.outputs.acrLoginServer
output postgresFqdn string = postgres.outputs.serverFqdn
output appConfigEndpoint string = appConfig.outputs.appConfigEndpoint
output redisHostName string = redis.outputs.redisHostName
output redisSslPort int = redis.outputs.redisSslPort
output storageAccount string = storage.outputs.storageAccountName
output apiIngressFqdn string = apiApp.outputs.ingressFqdn
output adminUiIngressFqdn string = adminUiApp.outputs.ingressFqdn
output frontDoorHostName string = afd.outputs.frontDoorEndpointHostName

