

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
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys:[
            {
              keyData:'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCXwJDohmnTxEH7F6/IR9AgApGWUT671Nu/Y4pln2XVk0YtswnkeE4aVnsrWvOpLVxv5alL22VR5VP3vyMd03GsLadwd40pZpdNiOTygfoaaURMzTkaBs+KSltQvFtAfgOMoO0f/zlgfyVzK/1DdwaAu1LFLMB5vpCP76pDu1oL6k9vK7DgiFEKiIBMoTwC9ak/Ois6/NUbupH7pv6L616z7qUX0Jz5ehSfrI3C22+UcrBxJspfWv/+pcGOZ1lICiw7VPvt/++f0XNUG/3KxsWw0V9klP7FaFyY6Z3NuA8Pb1GBmYSVcZY9nd2YPuXYH8Y92dZsibHMv2MEwvtC//FuzadCtNWlS+34Qho8PdwzA8swA4vd6KDwYKmhsHPrgxE25DvyxeKDPYfnFlYNdoD1gRXgGCGbjoUSJcjD7FUaey1iWUhQ1p0iHHUb0wHfJ70DtWsP/VUypAR/dBlTgYL0kpoIvmxZbytBVkxsBOfxfin9zlueN3sM2fq6sfMYCOoiNMKKQXnOw1qkwuviitX/ewgi9zTRjLdLYEw4e5rHe5YG1v0wTio14/NQIngeex8NvdfTTuxd2C6oDPJ19SqCA5bz2+tOMK57vCBtlo2/VJhYLcUZgSI3wbGWNobIFBAf/xOhYn4HN7Jthu6jAk4C3iuEeYv8UiUf9ufhLocjwQ== sbcAdminAcct'
              path: '/home/${localAdminName}/.ssh/authorized_keys'
            }
          ]
        }
      }
    }

    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-pro-bionic'
        sku: 'pro-18_04-lts-gen2'
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
