param name string
param location string
param gatewayType string = 'Vpn'
param vpnType string = 'RouteBased'
param vpnGeneration string = 'Generation1'
param skuName string = 'VpnGw1'

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2022-11-01' existing = {
  name: 'ip-vgn-${name}'
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: 'vnet-${name}'
}

// Virtual Network Gateway can only be created in subnet with name 'GatewaySubnet'
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  name: 'GatewaySubnet'
  parent: virtualNetwork
}

resource gateway 'Microsoft.Network/virtualNetworkGateways@2023-02-01' = {
  name: 'vng-${name}'
  location: location
  properties: {
    gatewayType: gatewayType
    vpnType: vpnType
    vpnGatewayGeneration: vpnGeneration
    sku: {
      name: skuName
      tier: skuName
    }
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          publicIPAddress: {
            id: publicIPAddress.id
          }
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}
