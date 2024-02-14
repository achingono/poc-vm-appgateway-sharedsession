param name string
param location string
param kind string = 'StorageV2'
param sku string = 'Standard_LRS'
param instances array

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  // https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#storage-blob-data-contributor
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource virtualMachines 'Microsoft.Compute/virtualMachines@2023-03-01' existing = [for (instance, i) in instances: {
  name: 'vm-${instance.name}-${name}'
}]

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: 'stg${replace(name,'-','')}'
  location: location
  kind: kind
  sku: {
    name: sku
  }
  properties: {
    allowBlobPublicAccess: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  parent: storageAccount
  name: 'default'
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  parent: blobService
  name: name
  properties: {
    publicAccess: 'Blob'
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for (instance, i) in instances: {
  name: guid(resourceGroup().id, virtualMachines[i].id, roleDefinition.id)
  scope: storageAccount
  properties: {
    roleDefinitionId: roleDefinition.id
    principalId: virtualMachines[i].identity.principalId
  }
}]
