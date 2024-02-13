@minLength(1)
@maxLength(20)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param name string
param location string
param uniqueSuffix string
@secure()
param adminUsername string
@secure()
param adminPassword string
param databasePackageName string
param sourcePackageName string
param instances array = [
  {
    name: 'app'
    type: 'app'
    pattern: '/*'
  }
  {
    name: 'api'
    type: 'api'
    pattern: '/api/*'
  }
]

var resourceName = '${name}-${uniqueSuffix}'

targetScope = 'subscription'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: 'rg-${name}-${location}-${uniqueSuffix}'
  location: location
  tags: {
    environment: name
  }
}

module publicIPAddress 'modules/publicIPAddress.bicep' = {
  name: '${deployment().name}--publicIPAddress'
  scope: resourceGroup
  params:{
    name: resourceName
    location: resourceGroup.location
  }
}

module virtualNetwork 'modules/virtualNetwork.bicep' = {
  name: '${deployment().name}--virtualNetwork'
  scope: resourceGroup
  params:{
    name: resourceName
    location: resourceGroup.location
  }
}

module virtualNetworkGateway 'modules/virtualNetworkGateway.bicep' = {
  name: '${deployment().name}--virtualNetworkGateway'
  scope: resourceGroup
  dependsOn: [
    publicIPAddress
    virtualNetwork
  ]
  params:{
    name: resourceName
    location: resourceGroup.location
  }
}

module networkSecurityGroup 'modules/networkSecurityGroup.bicep' = {
  name: '${deployment().name}--networkSecurityGroup'
  scope: resourceGroup
  params:{
    name: resourceName
    location: resourceGroup.location
  }
}

module keyVault 'modules/keyVault.bicep' = {
  name: '${deployment().name}--keyVault'
  scope: resourceGroup
  params:{
    name: resourceName
    location: resourceGroup.location
  }
}

module applicationGateway 'modules/applicationGateway.bicep' = {
  name: '${deployment().name}--applicationGateway'
  scope: resourceGroup
  dependsOn: [
    publicIPAddress
    virtualNetwork
    keyVault
  ]
  params:{
    name: resourceName
    location: resourceGroup.location
    instances: instances
  }
}

module networkInterface 'modules/networkInterface.bicep' = {
  name: '${deployment().name}--networkInterface'
  scope: resourceGroup
  dependsOn: [
    virtualNetwork
    networkSecurityGroup
    applicationGateway
  ]
  params:{
    name: resourceName
    location: resourceGroup.location
    instances: instances
  }
}

module virtualMachine 'modules/virtualMachine.bicep' = {
  name: '${deployment().name}--vm'
  scope: resourceGroup
  dependsOn: [
    networkInterface
  ]
  params:{
    name: resourceName
    location: resourceGroup.location
    adminUsername: adminUsername
    adminPassword: adminPassword
    instances: instances
  }
}

module command 'modules/runCommand.bicep' = {
  name: '${deployment().name}--command'
  scope: resourceGroup
  dependsOn: [
    virtualMachine
    storage
  ]
  params: {
    name: resourceName
    location: location
    instances: instances
    packageName: sourcePackageName
  }
}

module storage 'modules/storage.bicep' = {
  name: '${deployment().name}--storage'
  scope: resourceGroup
  params: {
    name: resourceName
    location: resourceGroup.location
  }
}

module sqlServer 'modules/sqlServer.bicep' = {
  name: '${deployment().name}--sqlServer'
  scope: resourceGroup
  dependsOn: [
    virtualNetwork
    storage
  ]
  params: {
    name: resourceName
    location: resourceGroup.location
    adminPassword: adminPassword
    adminUsername: adminUsername
    packageName: databasePackageName
  }
}

output resourceGroupName string = resourceGroup.name
output publicIPAddress string = publicIPAddress.outputs.ipAddress
output fqdn string = publicIPAddress.outputs.fqdn
output databaseServerName string = sqlServer.outputs.serverName
output databaseName string = sqlServer.outputs.databaseName
