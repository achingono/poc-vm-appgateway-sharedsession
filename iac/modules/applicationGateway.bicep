param name string
param location string
param sku string = 'Standard_v2'
param instances array

var keyVaultSecretsUserRole = resourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

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

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: 'kv-${name}'
}

module keyVaultCertificate 'br/public:deployment-scripts/create-kv-certificate:1.1.1' = {
  name: 'CreateFeKvCert'
  params: {
    akvName: keyVault.name
    certificateName: name
    certificateCommonName: publicIPAddress.properties.dnsSettings.fqdn
  }
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2021-05-01' = {
  name: 'gw-${name}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: sku
      tier: sku
    }
    sslCertificates: [
      {
        name: name
        properties: {
          keyVaultSecretId: keyVaultCertificate.outputs.certificateSecretIdUnversioned
        }
      }
    ]
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
        name: 'port_443'
        properties: {
          port: 443
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
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', 'gw-${name}', 'port_443')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', 'gw-${name}', name)
          }
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

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  scope: keyVault
  name: guid(applicationGateway.id, keyVault.id, keyVaultSecretsUserRole)
  properties: {
    roleDefinitionId: keyVaultSecretsUserRole
    principalType: 'ServicePrincipal'
    principalId: applicationGateway.identity.principalId
  }
}

module rbacPropagationDelay 'br/public:deployment-scripts/wait:1.0.1' = {
  name: 'DeploymentDelay'
  dependsOn: [
    roleAssignment
  ]
  params: {
    waitSeconds: 60
    location: location
  }
}
