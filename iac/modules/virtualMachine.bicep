param name string
param location string 
param size string = 'Standard_D2s_v3'
param publisher string = 'MicrosoftWindowsServer'
param offer string = 'WindowsServer'
param sku string = '2022-Datacenter'
param version string = 'latest'
@secure()
param adminUsername string
@secure()
param adminPassword string
param instances array

resource networkInterfaces 'Microsoft.Network/networkInterfaces@2022-05-01' existing = [for instance in instances: {
  name: 'nic-${instance.name}-${name}'
}]

resource virtualMachines 'Microsoft.Compute/virtualMachines@2023-03-01' = [for (instance, i) in instances: {
  name: 'vm-${instance.name}-${name}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: size
    }
    storageProfile: {
      imageReference: {
        publisher: publisher
        offer: offer
        sku: sku
        version: version
      }
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        deleteOption: 'Delete'
      }
      dataDisks: []
    }
    osProfile: {
      computerName: take(name, 15)
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
          enableHotpatching: false
        }
        enableVMAgentPlatformUpdates: false
      }
      secrets: []
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaces[i].id
          properties: {
            deleteOption: 'Detach'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}]

resource monitorAgent 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = [for (instance, i) in instances: {
  name: 'AzureMonitorWindowsAgent'
  parent: virtualMachines[i]
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.23.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}]

output vmNames array = [for (instance, i) in instances: virtualMachines[i].name]

