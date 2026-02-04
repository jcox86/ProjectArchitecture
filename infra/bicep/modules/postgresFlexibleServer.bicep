/*
module: infra.bicep.modules.postgresFlexibleServer
purpose: Provision Azure Database for PostgreSQL Flexible Server and baseline databases (catalog + tenant_shared).
exports:
  - outputs.serverId
  - outputs.serverName
  - outputs.serverFqdn
patterns:
  - single_server_baseline: one server hosts multiple databases (catalog, tenant_shared, dedicated tenant DBs created at runtime)
notes:
  - User/role creation is handled via Flyway (not Bicep).
  - Network baseline is public with firewall rules; private networking is an optional hardening module.
*/

targetScope = 'resourceGroup'

param serverName string
param location string
param tags object

@description('Administrator username (non-secret).')
param administratorLogin string

@secure()
@description('Administrator password (secret).')
param administratorLoginPassword string

@allowed([
  '12'
  '13'
  '14'
  '15'
  '16'
])
param version string = '16'

@description('SKU tier for Postgres Flexible Server.')
@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param skuTier string = 'GeneralPurpose'

@description('SKU name (instance type), e.g., Standard_D2ds_v5.')
param skuName string = 'Standard_D2ds_v5'

@description('Storage size in GB.')
param storageSizeGB int = 128

@description('High availability mode.')
@allowed([
  'Disabled'
  'ZoneRedundant'
])
param haMode string = 'ZoneRedundant'

@description('Availability zone (when applicable).')
param availabilityZone string = '1'

@description('Backup retention days.')
param backupRetentionDays int = 7

@allowed([
  'Disabled'
  'Enabled'
])
param geoRedundantBackup string = 'Disabled'

@description('Whether to add firewall rule to allow Azure services (simplest baseline).')
param allowAzureServices bool = true

resource pg 'Microsoft.DBforPostgreSQL/flexibleServers@2021-06-01' = {
  name: serverName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    version: version
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    highAvailability: {
      mode: haMode
    }
    storage: {
      storageSizeGB: storageSizeGB
    }
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
    availabilityZone: availabilityZone
  }
}

// Baseline databases
resource dbCatalog 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2021-06-01' = {
  name: 'catalog'
  parent: pg
  properties: {}
}

resource dbTenantShared 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2021-06-01' = {
  name: 'tenant_shared'
  parent: pg
  properties: {}
}

// Firewall rule: allow Azure services (baseline convenience).
// NOTE: This should be tightened in hardened deployments.
resource fwAllowAzure 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2021-06-01' = if (allowAzureServices) {
  name: 'AllowAzureServices'
  parent: pg
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

output serverId string = pg.id
output serverName string = pg.name
output serverFqdn string = pg.properties.fullyQualifiedDomainName

