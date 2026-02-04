/*
module: infra.bicep.modules.containerAppApi
purpose: Provision the API Azure Container App with external ingress and multiple revisions enabled (blue/green ready).
exports:
  - outputs.containerAppId
  - outputs.containerAppName
  - outputs.ingressFqdn
patterns:
  - multiple_revisions: ACA revisions mode 'Multiple' for blue/green traffic splitting
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

@description('Container port exposed by the API.')
param targetPort int = 8080

@description('Minimum replicas (recommend >=2 for prod).')
param minReplicas int = 1

@description('Maximum replicas.')
param maxReplicas int = 10

@description('ACR login server for managed-identity pulls (optional).')
param acrLoginServer string = ''

resource api 'Microsoft.App/containerApps@2023-05-01' = {
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
    }
    template: {
      containers: [
        {
          name: 'api'
          image: image
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
      }
    }
  }
}

output containerAppId string = api.id
output containerAppName string = api.name
output ingressFqdn string = api.properties.configuration.ingress.fqdn
output principalId string = api.identity.principalId

