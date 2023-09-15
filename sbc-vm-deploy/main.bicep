targetScope = 'subscription'


// Resource group settings
param existingResourceGroupName string


// Vnet settings
param existingSBCvnetName string
param existingSBCVnetResourceGrpName string
    //Subnet settings
    // param sbcHAsubnetName string
    param sbcMGMTsubnetName string
    param sbcTrustedsubnetName string
    param sbcUnTrustedsubnetName string
    param hfeToFlow3subnetName string
    param hfeToInternalsubnetName string

//Vm settings
@secure()
param localAdminName string
@secure()
param virtualVmSize string
// param sbcVmNames array = [
//   {
//     name: '${vmName}-sbc1'
//   }
//   {
//     name: '${vmName}-sbc2'
//   }
// ]

// Storage settings
param storageRdm string = take('${uniqueString(existingResourceGroupName)}${uniqueString(subscription().id)}', 3)
param storageAccoutNames array = [
  {
    name: 'dilzprodstghfestorage${storageRdm}'
  }
  {
    name: 'dilzprodstgdiagstore${storageRdm}'
  }
]

resource sbcResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: existingResourceGroupName
}


// Vnet section

resource existingSBCvnet 'Microsoft.Network/virtualNetworks@2023-02-01' existing = {
  scope: resourceGroup(existingSBCVnetResourceGrpName)
  name: existingSBCvnetName
}

//Subnet section

resource sbcMgmtSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-02-01' existing = {
  parent: existingSBCvnet
  name: sbcMGMTsubnetName
}

// resource sbcHASubnet 'Microsoft.Network/virtualNetworks/subnets@2023-02-01' existing = {
//   parent: existingSBCvnet
//   name: sbcHAsubnetName
// }

resource sbcTrustedSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-02-01' existing = {
  parent: existingSBCvnet
  name: sbcTrustedsubnetName
}

resource sbcUntrustedSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-02-01' existing = {
  parent: existingSBCvnet
  name: sbcUnTrustedsubnetName
}

resource hfeToFlow3Subnet 'Microsoft.Network/virtualNetworks/subnets@2023-02-01' existing = {
  parent: existingSBCvnet
  name: hfeToFlow3subnetName
}

resource existingInternalNetorOtherSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-02-01' existing = {
  parent: existingSBCvnet
  name: hfeToInternalsubnetName
}

// module sbcVirtualMachines 'modules/sbcVms.bicep' = [for i in sbcVmNames: {
//   scope: resourceGroup(sbcResourceGroup.name)
//   name: '${i.name}'
//   params: {
//     vmName: '${i.name}'
//     location: sbcResourceGroup.location
//     tags: sbcResourceGroup.tags
//     vnetId: existingSBCvnet.id
//     mgmtSubnetName: sbcMgmtSubnet.name
//     HAsubnetName: sbcHASubnet.name
//     trustedSubnetName: sbcTrustedSubnet.name
//     UntrustedSubnetName: sbcUntrustedSubnet.name
//     localAdminName: localAdminName
//     localAdminPassword: localAdminPass
//     vmSize: virtualVmSize
//   }
// }]

module voiceStorage 'modules/storageAcct.bicep' = [ for each in storageAccoutNames : {
  scope: resourceGroup(sbcResourceGroup.name)
  name: '${each.name}'
  params: {
    storageAccountName: '${each.name}'
    storageAccountlocation: sbcResourceGroup.location
    blobContainerName: '${each.name}'
  }
}
]

module hfeOne 'modules/hfeVms.bicep' =  {
  scope: resourceGroup(sbcResourceGroup.name)
  name: 'hfe1'
  params: {
    vmName: 'dilz-vm-cl1vfe-1d'
    location: sbcResourceGroup.location
    tags: sbcResourceGroup.tags
    vnetId: existingSBCvnet.id
    primaryNic: hfeToFlow3Subnet.name
    secondNic: sbcMgmtSubnet.name
    thirdNic: sbcUntrustedSubnet.name
    localAdminName: localAdminName
    vmSize: virtualVmSize
  }
}

module hfeTwo 'modules/hfeVms.bicep' =  {
  scope: resourceGroup(sbcResourceGroup.name)
  name: 'hfe2'
  params: {
    vmName: 'dilz-vm-cl1vfe-2d'
    location: sbcResourceGroup.location
    tags: sbcResourceGroup.tags
    vnetId: existingSBCvnet.id
    primaryNic: existingInternalNetorOtherSubnet.name
    secondNic: sbcMgmtSubnet.name
    thirdNic: sbcTrustedSubnet.name
    localAdminName: localAdminName
    vmSize: virtualVmSize
  }
}
