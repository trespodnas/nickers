

// Nsg settings
param sbcNsgId string

// Vnet settings
param virtualNetworkName string
param virtualNetworkLocation string
param virtualNetworkTags object
param virtualNetworkAddressSpace string

// HA subnet settings
param sbcHAnetworkSubnetName string
param sbcHAnetworkSubnetPrefix string


// Mgmt subnet settings
param sbcMgmtNetworkSubnetName string
param sbcMgmtNetworkSubnetPrefix string

// Trusted subnet settings
param sbcTrustedNetworkSubnetName string
param sbcTrustedNetworkSubnetPrefix string

// Untrusted subnet settings
param sbcUntrustedNetworkSubnetName string
param sbcUntrustedNetworkSubnetPrefix string

// FE public
param sbcFePublicName string
param sbcFePublicPrefix string

// FE internal 
param sbcFeInternalName string
param sbcFeInternalPrefix string



resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: virtualNetworkName
  location: virtualNetworkLocation
  tags: virtualNetworkTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressSpace
      ]
    }
    subnets: [
      {
        name: sbcHAnetworkSubnetName
        properties: {
          addressPrefix: sbcHAnetworkSubnetPrefix
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
         }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: sbcMgmtNetworkSubnetName
        properties: {
          addressPrefix: sbcMgmtNetworkSubnetPrefix
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: sbcTrustedNetworkSubnetName
        properties: {
          addressPrefix: sbcTrustedNetworkSubnetPrefix
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: sbcUntrustedNetworkSubnetName
        properties: {
          addressPrefix: sbcUntrustedNetworkSubnetPrefix
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: sbcFeInternalName
        properties: {
          addressPrefix: sbcFeInternalPrefix
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: sbcFePublicName
        properties: {
          addressPrefix: sbcFePublicPrefix
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          networkSecurityGroup: {
            id: sbcNsgId
          }
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

output vnetId string = virtualNetwork.id
