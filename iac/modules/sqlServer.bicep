param name string
param location string
@secure()
param adminUsername string
@secure()
param adminPassword string
param databaseSku string = 'Basic'
param databaseTier string = 'Basic'
param databaseCapacity int = 5


resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: 'vnet-${name}'
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  name: 'default'
  parent: virtualNetwork
}

resource sqlserver 'Microsoft.Sql/servers@2022-11-01-preview' = {
  name: 'sql-${name}'
  location: location
  properties: {
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
  }
}

resource virtualNetworkRule 'Microsoft.Sql/servers/virtualNetworkRules@2021-11-01' = {
  name: 'AllowSubnetIps'
  parent: sqlserver
  properties: {
    virtualNetworkSubnetId: subnet.id
  }
}

resource database 'Microsoft.Sql/servers/databases@2021-05-01-preview' = {
  name: 'db-${name}'
  parent: sqlserver
  location: location
  sku: {
    name: databaseSku
    tier: databaseTier
    capacity: databaseCapacity
  }
}
