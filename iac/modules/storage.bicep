param name string
param location string
param kind string = 'StorageV2'
param sku string = 'Standard_LRS'

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
