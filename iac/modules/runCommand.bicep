param name string
param location string
param instances array

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
  }
}]
