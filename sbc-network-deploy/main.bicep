targetScope = 'subscription'

// Resource Group details
param sbcResourceGroupName string
param sbcResourceGroupLocation string
param sbcResourceGroupTags  object

// Nsg details
param sbcFePublicNameSubnetNSG string = 'publicSubnetNsg'
param sbcFeInternalNameSubnetNsg string = 'internalSubnetNsg'
param sbcUntrustedNetworkSubnetNsg string = 'unTrustedSubnetNsg'
param sbcTrustedNetworkSubnetNsg string = 'trustedSubnetNsg'
param sbcMgmtNetworkSubnetNsg string = 'mgmtSubnetNsg'
param sbcHAnetworkSubnetNsg string = 'HASubnetNsg'
param sbcNsgLocation string = sbcResourceGroupLocation


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

module publicSubnetNSG 'modules/publicSubnetNsg.bicep' = {
  scope: resourceGroup(sbcResourceGroupName)
  name: sbcFePublicNameSubnetNSG
  params: {
    nsgName: sbcFePublicNameSubnetNSG
    nsgLocation: sbcNsgLocation
    }
    dependsOn:[
      sbcResourceGroup
    ]
}

module internalSubnetNsg 'modules/nsgGeneric.bicep' = {
  scope: resourceGroup(sbcResourceGroupName)
  name: sbcFeInternalNameSubnetNsg
  params:{
    nsgName: sbcFeInternalNameSubnetNsg
    nsgLocation:sbcNsgLocation
  }
}

module unTrustedSubnetNsg 'modules/nsgGeneric.bicep' = {
  scope: resourceGroup(sbcResourceGroupName)
  name: sbcUntrustedNetworkSubnetNsg
  params:{
    nsgName: sbcUntrustedNetworkSubnetNsg
    nsgLocation:sbcNsgLocation
  }
}

module trustedSubnetNsg 'modules/nsgGeneric.bicep' = {
  scope: resourceGroup(sbcResourceGroupName)
  name: sbcTrustedNetworkSubnetNsg
  params:{
    nsgName: sbcTrustedNetworkSubnetNsg
    nsgLocation:sbcNsgLocation
  }
}

module mgmtSubnetNsg 'modules/nsgGeneric.bicep' = {
  scope: resourceGroup(sbcResourceGroupName)
  name: sbcMgmtNetworkSubnetNsg
  params:{
    nsgName: sbcMgmtNetworkSubnetNsg
    nsgLocation:sbcNsgLocation
  }
}

module HASubnetNsg 'modules/nsgGeneric.bicep' = {
  scope: resourceGroup(sbcResourceGroupName)
  name: sbcHAnetworkSubnetNsg
  params:{
    nsgName: sbcHAnetworkSubnetNsg
    nsgLocation:sbcNsgLocation
  }
}

module sbcVnetDeployment 'modules/vnet.bicep' = {
  scope: resourceGroup(sbcResourceGroupName)
  name: 'sbcVnetDeployment'
  params: {
    sbcFePublicNameSubnetNsg: publicSubnetNSG.outputs.nsgId
    sbcFeInternalNameSubnetNsg: internalSubnetNsg.outputs.nsgId
    sbcUntrustedNetworkSubnetNsg: unTrustedSubnetNsg.outputs.nsgId
    sbcTrustedNetworkSubnetNsg: trustedSubnetNsg.outputs.nsgId
    sbcMgmtNetworkSubnetNsg: mgmtSubnetNsg.outputs.nsgId
    sbcHAnetworkSubnetNsg: HASubnetNsg.outputs.nsgId
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
    publicSubnetNSG, internalSubnetNsg, unTrustedSubnetNsg, trustedSubnetNsg, mgmtSubnetNsg, HASubnetNsg

  ]
}
