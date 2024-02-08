param name string
param location string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: 'vnet-${name}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'gateway'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
      {
        name: 'backend'
        properties: {
          addressPrefix: '10.0.3.0/24'
          serviceEndpoints: [
            {
              service: 'Microsoft.Sql'
              locations: [
                location
              ]
            }
          ]
        }
      }
      // Virtual Network Gateway can only be created in subnet with name 'GatewaySubnet'
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.4.0/24'
        }
      }
    ]
    enableDdosProtection: false
  }
}
