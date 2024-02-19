param name string
param location string
param skuName string = 'Basic'
param skuFamily string = 'C'
param skuCapacity int = 0

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: 'vnet-${name}'
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  name: 'backend'
  parent: virtualNetwork
}

resource redis 'Microsoft.Cache/redis@2020-12-01' = {
  name: 'redis-${name}'
  location: location
  properties: {
    sku: {
      name: skuName
      family: skuFamily
      capacity: skuCapacity
    }
    enableNonSslPort: false
  }
}

resource neworkLink 'Microsoft.Cache/redis/virtualNetworkLinks@2020-12-01' = {
  name: 'link-redis-${name}'
  parent: redis
  properties: {
    subnets: [
      {
        id: subnet.id
      }
    ]
  }
}

resource firewallRule 'Microsoft.Cache/redis/firewallRules@2020-12-01' = {
  name: replace('rule-redis-${name}','-','')
  parent: redis
  properties: {
    startIP: '10.0.3.0'
    endIP: '10.0.3.255'
  }
}
