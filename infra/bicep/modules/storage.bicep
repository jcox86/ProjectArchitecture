/*
module: infra.bicep.modules.storage
purpose: Provision a Storage Account used for Azure Storage Queues (async work) and Blob Storage (object storage).
exports:
  - outputs.storageAccountId
  - outputs.storageAccountName
  - outputs.blobEndpoint
  - outputs.queueEndpoint
patterns:
  - secure_by_default: TLS1_2+, no public blob access
notes:
  - For production, consider ZRS/GZRS where appropriate; parameterize redundancy by environment.
*/

targetScope = 'resourceGroup'

param storageAccountName string
param location string
param tags object

@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
])
param skuName string = 'Standard_LRS'

resource st 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: 'Enabled'
  }
}

// Blob containers
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  name: 'default'
  parent: st
}

resource attachmentsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: 'attachments'
  parent: blobService
  properties: {
    publicAccess: 'None'
  }
}

// Queues
resource queueService 'Microsoft.Storage/storageAccounts/queueServices@2023-05-01' = {
  name: 'default'
  parent: st
}

resource workQueue 'Microsoft.Storage/storageAccounts/queueServices/queues@2023-05-01' = {
  name: 'work'
  parent: queueService
}

resource workPoisonQueue 'Microsoft.Storage/storageAccounts/queueServices/queues@2023-05-01' = {
  name: 'work-poison'
  parent: queueService
}

resource outboxQueue 'Microsoft.Storage/storageAccounts/queueServices/queues@2023-05-01' = {
  name: 'outbox'
  parent: queueService
}

resource outboxPoisonQueue 'Microsoft.Storage/storageAccounts/queueServices/queues@2023-05-01' = {
  name: 'outbox-poison'
  parent: queueService
}

output storageAccountId string = st.id
output storageAccountName string = st.name
output blobEndpoint string = st.properties.primaryEndpoints.blob
output queueEndpoint string = st.properties.primaryEndpoints.queue

