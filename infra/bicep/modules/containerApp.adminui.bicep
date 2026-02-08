/*
module: infra.bicep.modules.containerAppAdminUi
purpose: Provision the Admin UI Azure Container App (SPA) with external ingress and multiple revisions enabled.
exports:
  - outputs.containerAppId
  - outputs.containerAppName
  - outputs.ingressFqdn
patterns:
  - spa_hosting: static assets served from container (e.g., nginx)
notes:
  - Image defaults to a placeholder; app pipeline updates image to built AdminUi container later.
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

@description('Container port exposed by the SPA server.')
param targetPort int = 80

@description('Minimum replicas.')
param minReplicas int = 1

@description('Maximum replicas.')
param maxReplicas int = 5

@description('Optional scale rules override. If empty, a default HTTP concurrent-requests rule is used.')
param scaleRules array = []

@description('Default concurrent requests per replica for the HTTP scaler (used when scaleRules is empty).')
param httpConcurrentRequests int = 100

@description('ACR login server for managed-identity pulls (optional).')
param acrLoginServer string = ''

var defaultScaleRules = [
  {
    name: 'http'
    http: {
      metadata: {
        concurrentRequests: string(httpConcurrentRequests)
      }
    }
  }
]

var effectiveScaleRules = (length(scaleRules) > 0 ? scaleRules : defaultScaleRules)

resource adminui 'Microsoft.App/containerApps@2023-05-01' = {
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
      ingress: {
        external: true
        targetPort: targetPort
        transport: 'auto'
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
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
          name: 'adminui'
          image: image
          env: env
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: effectiveScaleRules
      }
    }
  }
}

output containerAppId string = adminui.id
output containerAppName string = adminui.name
output ingressFqdn string = adminui.properties.configuration.ingress.fqdn
output principalId string = adminui.identity.principalId

