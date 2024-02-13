param name string
param location string
@secure()
param adminUsername string
@secure()
param adminPassword string
param databaseSku string = 'Basic'
param databaseTier string = 'Basic'
param databaseCapacity int = 5
param packageName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: 'vnet-${name}'
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  name: 'backend'
  parent: virtualNetwork
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: 'stg${replace(name,'-','')}'
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' existing = {
  parent: storageAccount
  name: 'default'
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' existing = {
  parent: blobService
  name: name
}

resource server 'Microsoft.Sql/servers@2022-11-01-preview' = {
  name: 'sql-${name}'
  location: location
  properties: {
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
  }
}

resource virtualNetworkRule 'Microsoft.Sql/servers/virtualNetworkRules@2021-11-01' = {
  name: 'AllowSubnetIps'
  parent: server
  properties: {
    virtualNetworkSubnetId: subnet.id
  }
}

resource database 'Microsoft.Sql/servers/databases@2021-05-01-preview' = {
  name: 'db-${name}'
  parent: server
  location: location
  sku: {
    name: databaseSku
    tier: databaseTier
    capacity: databaseCapacity
  }
}

// https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/template-tutorial-deploy-sql-extensions-bacpac
resource extension 'Microsoft.Sql/servers/databases/extensions@2022-05-01-preview' = {
  name: 'Import'
  parent: database
  properties: {
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
    authenticationType: 'SQL'
    operationMode: 'Import'
    storageKey: storageAccount.listKeys().keys[0].value
    storageKeyType: 'StorageAccessKey'
    storageUri: '${storageAccount.properties.primaryEndpoints.blob}/${blobContainer.name}/${packageName}'
  }
}

output serverName string = server.properties.fullyQualifiedDomainName
output databaseName string = database.name
