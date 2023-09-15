

// Nic options
param vnetId string
param primaryNic string
// param HAsubnetName  string
param secondNic string
param thirdNic string



// Vm options
param vmName string
param tags object
param location string
param localAdminName string
@secure()
param localAdminPassword string
param vmSize string
param hfeSecondaryNics array = [
  {
    name: 'nic-${vmName}-1'
    subnet: primaryNic
  }
  {
    name: 'nic-${vmName}-2'
    subnet: secondNic
  }
  {
    name: 'nic-${vmName}-3'
    subnet: thirdNic
  }

]

resource hfeNics 'Microsoft.Network/networkInterfaces@2023-02-01' = [for nic in hfeSecondaryNics: {
  name: nic.name
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig-${nic.subnet}'
        properties: {
          subnet: {   
            id: '${vnetId}/subnets/${nic.subnet}'
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    enableAcceleratedNetworking: true
  }
}]


resource hveVms 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    osProfile: {
      computerName: vmName
      adminUsername: localAdminName
      adminPassword: localAdminPassword
    }

    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      encryptionAtHost: true
      securityType: 'TrustedLaunch'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: hfeNics[0].id
          properties: {
            primary: true
            deleteOption: 'Delete'
          }
        }
        {
          id: hfeNics[1].id
          properties: {
            primary: false
            deleteOption: 'Delete'
          }
        }
        {
          id: hfeNics[2].id
          properties: {
            primary: false
            deleteOption: 'Delete'
          }
        }
      ]
    }
  }
  dependsOn: [
    hfeNics
  ]
}
