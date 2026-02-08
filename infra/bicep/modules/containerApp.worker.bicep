/*
module: infra.bicep.modules.containerAppWorker
purpose: Provision the Worker Azure Container App (no ingress) with multiple revisions enabled.
exports:
  - outputs.containerAppId
  - outputs.containerAppName
patterns:
  - background_worker: no ingress; scale rules added later (e.g., queue depth via KEDA)
notes:
  - Image defaults to a placeholder; app pipeline updates image to ACR later.
*/

targetScope = 'resourceGroup'

param name string
param location string
param tags object
param managedEnvironmentId string

@description('Container image reference. App pipeline will update this to ACR image tags.')
param image string

@description('Container app secrets (optionally Key Vault-backed). Items should be compatible with ACA `configuration.secrets`.')
param secrets array = []

@description('Environment variables for the container. Items should be compatible with ACA `template.containers[].env`.')
param env array = []

@description('Minimum replicas.')
param minReplicas int = 1

@description('Maximum replicas.')
param maxReplicas int = 5

@description('Optional scale rules (KEDA). Items should be compatible with ACA `template.scale.rules`.')
param scaleRules array = []

@description('ACR login server for managed-identity pulls (optional).')
param acrLoginServer string = ''

resource worker 'Microsoft.App/containerApps@2023-05-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: managedEnvironmentId
    configuration: {
      activeRevisionsMode: 'Multiple'
      registries: empty(acrLoginServer) ? [] : [
        {
          server: acrLoginServer
          identity: 'system'
        }
      ]
      secrets: secrets
    }
    template: {
      containers: [
        {
          name: 'worker'
          image: image
          env: env
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: scaleRules
      }
    }
  }
}

output containerAppId string = worker.id
output containerAppName string = worker.name
output principalId string = worker.identity.principalId

