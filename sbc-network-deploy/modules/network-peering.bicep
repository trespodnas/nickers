param sourceNetworkName string
param remoteVirtualNetworkResourceIds array

resource virtualNetworkPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-02-01' = [for remoteVirtualNetworkResourceId in remoteVirtualNetworkResourceIds: {
  name: '${sourceNetworkName}/to-${split(remoteVirtualNetworkResourceId, '/')[8]}'
  properties: {
    allowForwardedTraffic: true
    remoteVirtualNetwork: {
      id: remoteVirtualNetworkResourceId
    }
  }
}]
