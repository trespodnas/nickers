

//Nic options
param vnetId string
param mgmtSubnetName string
param HAsubnetName  string
param trustedSubnetName string
param UntrustedSubnetName string



// Vm options
param vmName string
param tags object
param location string
param localAdminName string
@secure()
param localAdminPassword string
param vmSize string
param sbcSecondaryNics array = [
  {
    name: 'nic-${vmName}-1'
    subnet: mgmtSubnetName
  }
  {
    name: 'nic-${vmName}-2'
    subnet: HAsubnetName
  }
  {
    name: 'nic-${vmName}-3'
    subnet: trustedSubnetName
  }
  {
    name: 'nic-${vmName}-4'
    subnet: UntrustedSubnetName
  }

]

resource sbcNics 'Microsoft.Network/networkInterfaces@2023-02-01' = [for nic in sbcSecondaryNics: {
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


resource sbcVms 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: 'vm-${vmName}'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    osProfile: {
      computerName: 'vm-${vmName}'
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
          id: sbcNics[0].id
          properties: {
            primary: true
            deleteOption: 'Delete'
          }
        }
        {
          id: sbcNics[1].id
          properties: {
            primary: false
            deleteOption: 'Delete'
          }
        }
        {
          id: sbcNics[2].id
          properties: {
            primary: false
            deleteOption: 'Delete'
          }
        }
        {
          id: sbcNics[3].id
          properties: {
            primary: false
            deleteOption: 'Delete'
          }
        }
      ]
    }
  }
  dependsOn: [
    sbcNics
  ]
}
