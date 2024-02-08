param name string
param location string
param instances array 

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: 'vnet-${name}'
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  name: 'backend'
  parent: virtualNetwork
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-11-01' existing = {
  name: 'nsg-${name}'
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2021-05-01' existing = {
  name: 'gw-${name}'
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2022-05-01' = [for instance in instances: {
  name: 'nic-${instance.name}-${name}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'default'
        type: 'Microsoft.Network/networkInterfaces/ipConfigurations'
        properties: {
          subnet: {
            id: subnet.id
          }
          applicationGatewayBackendAddressPools: [
            {
              id: '${applicationGateway.id}/backendAddressPools/${instance.name}BackendPool'
            }
          ]
          primary: true
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
}]
