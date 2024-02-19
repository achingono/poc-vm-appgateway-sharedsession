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
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
  }
}

resource endpoint 'Microsoft.Network/privateEndpoints@2022-11-01' = {
  name: 'pe-${redis.name}'
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'pe-${redis.name}'
        properties: {
          privateLinkServiceId: redis.id
          groupIds: [
            'redisCache'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    subnet: {
      id: subnet.id
    }
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: 'privatelink.redis.cache.windows.net'
  location: 'global'
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${privateDnsZone.name}/${uniqueString(virtualNetwork.id)}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

resource record 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  name: '${privateDnsZone.name}/${redis.name}'
  properties: {
    aRecords: [
      {
        ipv4Address: endpoint.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]
    ttl: 3600
  }
}

resource firewallRule 'Microsoft.Cache/redis/firewallRules@2020-12-01' = {
  name: replace('rule-${redis.name}', '-', '')
  parent: redis
  properties: {
    startIP: '10.0.3.0'
    endIP: '10.0.3.255'
  }
}
