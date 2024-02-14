param name string
param location string
param instances array
param packageName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: 'stg${replace(name,'-','')}'
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' existing = {
  parent: storageAccount
  name: 'default'
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' existing = {
  parent: blobService
  name: name
}

resource virtualMachines 'Microsoft.Compute/virtualMachines@2023-03-01' existing = [for (instance, i) in instances: {
  name: 'vm-${instance.name}-${name}'
}]

resource deploymentscript 'Microsoft.Compute/virtualMachines/runCommands@2022-03-01' = [for (instance, i) in instances: {
  parent: virtualMachines[i]
  name: 'RunPowerShellScript'
  location: location
  properties: {
    source: {
      script: loadTextContent('runCommand.ps1')
    }
    parameters: [
      {
        name: 'storageAccountName'
        value: storageAccount.name
      }
      {
        name: 'storageContainerName'
        value: blobContainer.name
      }
      {
        name: 'storageFileName'
        value: packageName
      }
      {
        name: 'storageKey'
        value: storageAccount.listKeys().keys[0].value
      }
    ]
    outputBlobUri: '${storageAccount.properties.primaryEndpoints.blob}${blobContainer.name}/runCommand-${instance.name}.log'
    errorBlobUri: '${storageAccount.properties.primaryEndpoints.blob}${blobContainer.name}/runCommand-${instance.name}-error.log'
  }
}]
