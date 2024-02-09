param name string
param location string
param gatewayType string = 'Vpn'
param vpnType string = 'RouteBased'
param vpnGeneration string = 'Generation1'
param skuName string = 'VpnGw1'

// https://github.com/Azure/azure-quickstart-templates/blob/master/quickstarts/microsoft.network/point-to-site-aad/main.bicep
var audienceMap = {
  AzureCloud: '41b23e61-6c1e-4545-b367-cd054e0ed4b4'
  AzureUSGovernment: '51bb15d4-3a4f-4ebf-9dca-40096fe32426'
  AzureGermanCloud: '538ee9e6-310a-468d-afef-ea97365856a9'
  AzureChinaCloud: '49f817b6-84ae-4cc0-928c-73f27289b3aa'
}
var tenantId = subscription().tenantId
var cloud = environment().name
var audience = audienceMap[cloud]
var tenant = uri(environment().authentication.loginEndpoint, tenantId)
var issuer = 'https://sts.windows.net/${tenantId}/'

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
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          '10.10.0.0/24'
        ]
      }
      vpnClientProtocols: [
        'OpenVPN'
      ]
      vpnAuthenticationTypes: [
        'AAD'
      ]
      aadTenant: tenant
      aadAudience: audience
      aadIssuer: issuer
    }
  }
}
