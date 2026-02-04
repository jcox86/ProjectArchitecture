/*
module: infra.bicep.modules.redis
purpose: Provision Azure Cache for Redis used for tenant routing cache and ABAC attribute cache.
exports:
  - outputs.redisId
  - outputs.redisHostName
  - outputs.redisSslPort
patterns:
  - ssl_only: disable non-TLS port
notes:
  - Access keys are secrets; store them in Key Vault (do not output).
*/

targetScope = 'resourceGroup'

param redisName string
param location string
param tags object

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param skuName string = 'Standard'

@description('Capacity: size tier (e.g., 0..6 depending on SKU).')
param skuCapacity int = 1

var skuFamily = (skuName == 'Premium' ? 'P' : (skuName == 'Basic' ? 'C' : 'C'))

resource redis 'Microsoft.Cache/Redis@2023-08-01' = {
  name: redisName
  location: location
  tags: tags
  properties: {
    sku: {
      name: skuName
      family: skuFamily
      capacity: skuCapacity
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

output redisId string = redis.id
output redisHostName string = redis.properties.hostName
output redisSslPort int = redis.properties.sslPort

