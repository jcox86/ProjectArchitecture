/*
module: infra.bicep.modules.resourceGroupLock
purpose: Apply a CanNotDelete lock to the current resource group (used from subscription-scope bootstrap).
exports: []
patterns:
  - resource_group_lock
*/

targetScope = 'resourceGroup'

@description('Name of the management lock resource.')
param lockName string

@description('Notes/justification for the lock.')
param notes string = 'Protect environment RG from accidental deletion. Disable only with explicit approval.'

resource lockRg 'Microsoft.Authorization/locks@2020-05-01' = {
  name: lockName
  properties: {
    level: 'CanNotDelete'
    notes: notes
  }
}

