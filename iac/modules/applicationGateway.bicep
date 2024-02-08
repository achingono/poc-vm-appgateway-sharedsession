param name string
param location string
param sku string = 'Standard_v2'
param instances array

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2022-11-01' existing = {
  name: 'ip-${name}'
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: 'vnet-${name}'
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  name: 'gateway'
  parent: virtualNetwork
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2021-05-01' = {
  name: 'gw-${name}'
  location: location
  properties: {
    sku: {
      name: sku
      tier: sku
    }
    gatewayIPConfigurations: [
      {
        name: 'IpConfiguration'
        properties: {
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'FrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [for instance in instances: {
      name: '${instance.name}BackendPool'
      properties: {}
    }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'HTTPSetting'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 20
          path: '/'
        }
      }
    ]
    httpListeners: [
      {
        name: 'Listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', 'gw-${name}', 'FrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', 'gw-${name}', 'port_80')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'RoutingRule'
        properties: {
          ruleType: 'PathBasedRouting'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', 'gw-${name}', 'Listener')
          }
          urlPathMap: {
            id: resourceId('Microsoft.Network/applicationGateways/urlPathMaps', 'gw-${name}', 'PathMap')
          }
        }
      }
    ]
    urlPathMaps: [
      {
        name: 'PathMap'
        properties: {
          defaultBackendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'gw-${name}', '${instances[0].name}BackendPool')
          }
          defaultBackendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', 'gw-${name}', 'HTTPSetting')
          }
          pathRules: [for instance in instances: {
            name: '${instance.name}PathRule'
            properties: {
              paths: [
                instance.pattern
              ]
              backendAddressPool: {
                id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'gw-${name}', '${instance.name}BackendPool')
              }
              backendHttpSettings: {
                id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', 'gw-${name}', 'HTTPSetting')
              }
            }
          }]
        }
      }
    ]
    enableHttp2: false
    autoscaleConfiguration: {
      minCapacity: 0
      maxCapacity: 10
    }
  }
  dependsOn: [
    publicIPAddress
  ]
}
