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

module networkSecurityGroup 'modules/networkSecurityGroup.bicep' = {
  name: '${deployment().name}--networkSecurityGroup'
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

module sqlServer 'modules/sqlServer.bicep' = {
  name: '${deployment().name}--sqlServer'
  scope: resourceGroup
  dependsOn: [
    virtualNetwork
  ]
  params: {
    name: resourceName
    location: resourceGroup.location
    adminPassword: adminPassword
    adminUsername: adminUsername
  }
}