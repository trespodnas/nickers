type subnetDefinitionType = {
  name: string
  prefix: string
}

param resourcePrefix string = 'dilz'
param environment string = 'prod'

param location string = resourceGroup().location

param tags object = {}

param afnetCidr string
param enclaveCidr string
param internalHubCidr string

param externalBoundaryFirewallIpAddress string
param bcapFirewallIpAddress string
param internalFirewallIpAddress string

param virtualNetworkAddressSpace string
param virtualNetworkName string = '${resourcePrefix}-vnet-sbc01-${environment}'

param fePublicSubnetDefinition subnetDefinitionType = {
  name: '${resourcePrefix}${environment}-net-snt-FEpublic'
  prefix: cidrSubnet(virtualNetworkAddressSpace, 27, 0)
}
param feInternalSubnetDefinition subnetDefinitionType = {
  name: '${resourcePrefix}${environment}-net-snt-FEinternal'
  prefix: cidrSubnet(virtualNetworkAddressSpace, 27, 1)
}
param untrustedSubnetDefinition subnetDefinitionType = {
  name: '${resourcePrefix}${environment}-net-snt-Untrusted'
  prefix: cidrSubnet(virtualNetworkAddressSpace, 27, 2)
}
param trustedSubnetDefinition subnetDefinitionType = {
  name: '${resourcePrefix}${environment}-net-snt-Trusted'
  prefix: cidrSubnet(virtualNetworkAddressSpace, 27, 3)
}
param mgmtSubnetDefinition subnetDefinitionType = {
  name: '${resourcePrefix}${environment}-net-snt-Mgmt'
  prefix: cidrSubnet(virtualNetworkAddressSpace, 27, 4)
}
param haSubnetDefinition subnetDefinitionType = {
  name: '${resourcePrefix}${environment}-net-snt-HA'
  prefix: cidrSubnet(virtualNetworkAddressSpace, 27, 5)
}
param privateEndpointSubnetDefinition subnetDefinitionType = {
  name: '${resourcePrefix}${environment}-net-snt-pep'
  prefix: cidrSubnet(virtualNetworkAddressSpace, 27, 6)
}

////////////////////////////////
// vars

var bcapInternetRoute = [
  {
    name: 'default_route'
    properties: {
      addressPrefix: '0.0.0.0/0'
      nextHopIpAddress: bcapFirewallIpAddress
      nextHopType: 'VirtualAppliance'
    }
  }
]

var externalInternetRoute = [
  {
    name: 'default_route'
    properties: {
      addressPrefix: '0.0.0.0/0'
      nextHopIpAddress: externalBoundaryFirewallIpAddress
      nextHopType: 'VirtualAppliance'
    }
  }
]

var sharedRoutes = [
  {
    name: 'internal_enclave_route'
    properties: {
      addressPrefix: enclaveCidr
      nextHopIpAddress: internalFirewallIpAddress
      nextHopType: 'VirtualAppliance'
    }
  }
  {
    name: 'afnet_route'
    properties: {
      addressPrefix: afnetCidr
      nextHopIpAddress: bcapFirewallIpAddress
      nextHopType: 'VirtualAppliance'
    }
  }
]

//////////////////////////
// Route Tables

resource bcapPreferredRouteTable 'Microsoft.Network/routeTables@2021-02-01' = {
  name: '${resourcePrefix}-bcap-preferred-routing'
  location: location
  tags: tags

  properties: {
    routes: concat(sharedRoutes, bcapInternetRoute)
  }
}

resource externalPreferredRouteTable 'Microsoft.Network/routeTables@2021-02-01' = {
  name: '${resourcePrefix}-external-preferred-routing'
  location: location
  tags: tags

  properties: {
    routes: concat(sharedRoutes, externalInternetRoute)
  }
}

//////////////////////////
// Network Security Group

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: '${resourcePrefix}-ribbon-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-Https-From-Enclave'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 500
          protocol: 'Tcp'
          destinationPortRanges: [
            '443' // https
          ]
          sourceAddressPrefix: enclaveCidr
          sourcePortRange: '*'
        }
      }
      {
        name: 'Allow-Bastion-From-Internal'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 500
          protocol: 'Tcp'
          destinationPortRanges: [
            '22' // ssh
            '443' // https
            '3389' // rdp
          ]
          sourceAddressPrefix: internalHubCidr
          sourcePortRange: '*'
        }
      }
      {
        name: 'Allow-FePublic-Internal'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 2000
          protocol: '*'
          destinationAddressPrefix: fePublicSubnetDefinition.prefix
          destinationPortRange: '*'
          sourceAddressPrefix: fePublicSubnetDefinition.prefix
          sourcePortRange: '*'
        }
      }
      {
        name: 'Allow-FeInternal-Internal'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 2001
          protocol: '*'
          destinationAddressPrefix: feInternalSubnetDefinition.prefix
          destinationPortRange: '*'
          sourceAddressPrefix: feInternalSubnetDefinition.prefix
          sourcePortRange: '*'
        }
      }
      {
        name: 'Allow-Untrusted-Internal'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 2002
          protocol: '*'
          destinationAddressPrefix: untrustedSubnetDefinition.prefix
          destinationPortRange: '*'
          sourceAddressPrefix: untrustedSubnetDefinition.prefix
          sourcePortRange: '*'
        }
      }
      {
        name: 'Allow-Trusted-Internal'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 2003
          protocol: '*'
          destinationAddressPrefix: trustedSubnetDefinition.prefix
          destinationPortRange: '*'
          sourceAddressPrefix: trustedSubnetDefinition.prefix
          sourcePortRange: '*'
        }
      }
      {
        name: 'Allow-Mgmt-Internal'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 2004
          protocol: '*'
          destinationAddressPrefix: mgmtSubnetDefinition.prefix
          destinationPortRange: '*'
          sourceAddressPrefix: mgmtSubnetDefinition.prefix
          sourcePortRange: '*'
        }
      }
      {
        name: 'Allow-HA-Internal'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 2005
          protocol: '*'
          destinationAddressPrefix: haSubnetDefinition.prefix
          destinationPortRange: '*'
          sourceAddressPrefix: haSubnetDefinition.prefix
          sourcePortRange: '*'
        }
      }
      {
        name: 'Allow-Private-Endpoint-Internal'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 2006
          protocol: '*'
          destinationAddressPrefix: privateEndpointSubnetDefinition.prefix
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
        }
      }
      {
        name: 'Default-Deny-Virtual-Network'
        properties: {
          access: 'Deny'
          direction: 'Inbound'
          priority: 2500
          protocol: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
      {
        name: 'Allow-Select-Internet-Outbound'
        properties: {
          access: 'Allow'
          direction: 'Outbound'
          priority: 50000
          protocol: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '*'
          sourceAddressPrefixes: [
            fePublicSubnetDefinition.prefix
            feInternalSubnetDefinition.prefix
          ]
          sourcePortRange: '*'
        }
      }
      {
        name: 'Default-Deny-Internet-Outbound'
        properties: {
          access: 'Deny'
          direction: 'Outbound'
          priority: 50100
          protocol: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
    ]
  }
}

////////////////////////////
// Virtual Network

var subnetDefs = [
  fePublicSubnetDefinition
  feInternalSubnetDefinition
  untrustedSubnetDefinition
  trustedSubnetDefinition
  mgmtSubnetDefinition
  haSubnetDefinition
]

var subnets = [for subnetDef in subnetDefs: {
  name: subnetDef.name
  properties: {
    addressPrefix: subnetDef.prefix
    privateEndpointNetworkPolicies: subnetDef.name == privateEndpointSubnetDefinition.name ? 'Enabled' : 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
    routeTable: {
      id: subnetDef.name == fePublicSubnetDefinition.name ? externalPreferredRouteTable.id : bcapPreferredRouteTable.id // only route public FE through external boundary
    }
  }
}
]

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: virtualNetworkName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressSpace
      ]
    }
    subnets: subnets
  }
}

output bcapPreferredRouteTableId string = bcapPreferredRouteTable.id
output bcapPreferredRouteTableName string = bcapPreferredRouteTable.name

output externalPreferredRouteTableId string = externalPreferredRouteTable.id
output externalPreferredRouteTableName string = externalPreferredRouteTable.name

output vnetName string = virtualNetwork.name
output vnetId string = virtualNetwork.id
