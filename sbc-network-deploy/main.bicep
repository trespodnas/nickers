targetScope = 'subscription'

// Resource Group details
param sbcResourceGroupName string
param sbcResourceGroupLocation string = deployment().location
param sbcResourceGroupTags object

// Vnet details
param sbcVnetName string
param sbcVnetBaseAddressSpace string

param enclaveCidr string
param afnetCidr string
param internalHubCidr string
param bcapFirewallIpAddress string
param externalBoundaryFirewallIpAddress string
param internalFirewallIpAddress string

param externalBoundaryHubSubscriptionId string
param externalBoundaryHubResourceGroupName string
param externalBoundaryHubNetworkName string

param bcapHubSubscriptionId string
param bcapHubResourceGroupName string
param bcapHubNetworkName string

param internalHubSubscriptionId string
param internalHubResourceGroupName string
param internalHubNetworkName string

////////////////////////////
// Resource group

resource sbcResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: sbcResourceGroupName
  location: sbcResourceGroupLocation
  tags: sbcResourceGroupTags
}

////////////////////////////
// Ribbon specific networking

module ribbonNetwork './modules/networking.bicep' = {
  scope: sbcResourceGroup
  name: 'sbc-networking-deploy'
  params: {
    location: sbcResourceGroupLocation
    afnetCidr: afnetCidr
    bcapFirewallIpAddress: bcapFirewallIpAddress
    enclaveCidr: enclaveCidr
    externalBoundaryFirewallIpAddress: externalBoundaryFirewallIpAddress
    internalFirewallIpAddress: internalFirewallIpAddress
    internalHubCidr: internalHubCidr
    virtualNetworkAddressSpace: sbcVnetBaseAddressSpace

    virtualNetworkName: sbcVnetName
  }
}

////////////////////////////
// Peerings

resource externalBoundaryHubNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  scope: resourceGroup(externalBoundaryHubSubscriptionId, externalBoundaryHubResourceGroupName)
  name: externalBoundaryHubNetworkName
}
resource bcapHubNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  scope: resourceGroup(bcapHubSubscriptionId, bcapHubResourceGroupName)
  name: bcapHubNetworkName
}
resource internalHubNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  scope: resourceGroup(internalHubSubscriptionId, internalHubResourceGroupName)
  name: internalHubNetworkName
}

module externalToRibbonPeering './modules/network-peering.bicep' = {
  scope: resourceGroup(externalBoundaryHubSubscriptionId, externalBoundaryHubResourceGroupName)
  name: 'external-to-ribbon-peering-deploy'
  params: {
    remoteVirtualNetworkResourceIds: [
      ribbonNetwork.outputs.vnetId
    ]
    sourceNetworkName: externalBoundaryHubNetworkName
  }
}

module bcapToRibbonPeering './modules/network-peering.bicep' = {
  scope: resourceGroup(bcapHubSubscriptionId, bcapHubResourceGroupName)
  name: 'bcap-to-ribbon-peering-deploy'
  params: {
    remoteVirtualNetworkResourceIds: [
      ribbonNetwork.outputs.vnetId
    ]
    sourceNetworkName: bcapHubNetworkName
  }
}

module internalToRibbonPeering './modules/network-peering.bicep' = {
  scope: resourceGroup(internalHubSubscriptionId, internalHubResourceGroupName)
  name: 'internal-to-ribbon-peering-deploy'
  params: {
    remoteVirtualNetworkResourceIds: [
      ribbonNetwork.outputs.vnetId
    ]
    sourceNetworkName: bcapHubNetworkName
  }
}

// Note: This *could* get moved into the `ribbonNetwork` module above since the scope is the same; would require passing quite a few more parameters though.
module ribbonToAllPeering './modules/network-peering.bicep' = {
  scope: sbcResourceGroup
  name: 'ribbont-to-all-peering-deploy'
  params: {
    remoteVirtualNetworkResourceIds: [
      externalBoundaryHubNetwork.id
      bcapHubNetwork.id
      internalHubNetwork.id
    ]
    sourceNetworkName: ribbonNetwork.outputs.vnetName
  }
}
