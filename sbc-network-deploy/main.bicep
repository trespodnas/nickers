targetScope = 'subscription'

// Resource Group details
param sbcResourceGroupName string
param sbcResourceGroupLocation string
param sbcResourceGroupTags  object

// Nsg details
param sbcNsgName string
param sbcNsgLocation string


// Vnet details
param sbcVnetName string
param sbcVnetBaseAddressSpace string
  // Subnet details
  param sbcHaNetworkName string
  param sbcHaNetworkPrefix string
  param sbcMgmtNetworkName string
  param sbcMgmtNetworkPrefix string
  param sbcTrustedNetworkName string
  param sbcTrustedNetworkPrefix string
  param sbcUnTrustedNetworkName string
  param sbcUnTrustedNetworkPrefix string
  param sbcFeInternalName string
  param sbcFeInternalPrefix string
  param sbcFePublicName string
  param sbcFePublicPrefix string


resource sbcResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: sbcResourceGroupName
  location: sbcResourceGroupLocation
  tags: sbcResourceGroupTags
}

module sbcNsg 'modules/nsg.bicep' = {
  scope: resourceGroup(sbcResourceGroupName)
  name: sbcNsgName
  params: {
    nsgName: sbcNsgName
    nsgLocation: sbcNsgLocation
    }
    dependsOn:[
      sbcResourceGroup
    ]
}


module sbcVnetDeployment 'modules/vnet.bicep' = {
  scope: resourceGroup(sbcResourceGroupName)
  name: 'sbcVnetDeployment'
  params: {
    sbcNsgId: sbcNsg.outputs.nsgId
    virtualNetworkName: sbcVnetName
    virtualNetworkLocation: sbcResourceGroup.location
    virtualNetworkTags: sbcResourceGroupTags
    virtualNetworkAddressSpace: sbcVnetBaseAddressSpace
    sbcHAnetworkSubnetName: sbcHaNetworkName
    sbcHAnetworkSubnetPrefix: sbcHaNetworkPrefix
    sbcMgmtNetworkSubnetName: sbcMgmtNetworkName
    sbcMgmtNetworkSubnetPrefix: sbcMgmtNetworkPrefix
    sbcTrustedNetworkSubnetName: sbcTrustedNetworkName
    sbcTrustedNetworkSubnetPrefix: sbcTrustedNetworkPrefix
    sbcUntrustedNetworkSubnetName: sbcUnTrustedNetworkName
    sbcUntrustedNetworkSubnetPrefix: sbcUnTrustedNetworkPrefix
    sbcFeInternalName: sbcFeInternalName
    sbcFeInternalPrefix: sbcFeInternalPrefix
    sbcFePublicName: sbcFePublicName
    sbcFePublicPrefix: sbcFePublicPrefix
  }
  dependsOn: [
    sbcNsg
  ]
}
