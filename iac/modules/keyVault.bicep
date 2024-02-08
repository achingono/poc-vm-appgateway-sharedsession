param name string
param location string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${name}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableSoftDelete: false
    enableRbacAuthorization: true
    accessPolicies: []
  }
}
