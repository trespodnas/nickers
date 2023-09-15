

// Nsg details
param nsgName string
param nsgLocation string


resource nsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: nsgName
  location: nsgLocation
  properties: {
    securityRules: [
      {
        name: 'dilzprod-net-nsg-sbc01'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '52.52.52.52/32'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 131
          direction: 'Inbound'
        }
      }
    ]
  }
}


output nsgName string = nsg.name
output nsgId string = nsg.id
