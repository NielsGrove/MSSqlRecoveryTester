

function New-AzureVmExample01 {
<#
.DESCRIPTION
  Sandbox for basic virtual SQL Server Database Engine server in Azure
.PARAMETER <Name>
  <parameter description>
.OUTPUTS
  (none)
.RETURNVALUE
  (none)
.LINK
  Microsoft Docs: Create and Manage Windows VMs with the Azure PowerShell module
  https://docs.microsoft.com/en-us/azure/virtual-machines/windows/tutorial-manage-vm
.NOTES
  2017-07-31  (Niels Grove-Rasmussen) Function created to implement sandbox inspired from Microsoft tutorial.
  2017-08-04T07:50:04Z  <function> finished with success. Duration = 00:07:38.5101958. [hh:mm:ss.ddd]
#>
[CmdletBinding()]
[OutputType([void])]
Param(
  #[Parameter(Mandatory=$true, ValueFromPipeLine=$true,HelpMessage='Take your time to write a good help message...')]
  #[string]$param1
)

Begin {
  $mywatch = [System.Diagnostics.Stopwatch]::StartNew()
  "{0:s}Z  ::  New-AzureVmExample" -f [System.DateTime]::UtcNow | Write-Verbose

  Import-Module -Name AzureRM

  Get-Module AzureRM

  'Log in to Azure...'
  Login-AzureRmAccount
}

Process {
  'Setting variables with common values...' #| Write-Verbose
  [string]$ResourceGroupName = 'SqlRecoveryRG'
  [string]$LocationName = 'WestEurope'
  [string]$SubnetName = 'SqlRecoverySubnet'
  [string]$vmName = 'SqlRecoveryVM'

  'Create Azure resource group...' #| Write-Verbose
  New-AzureRmResourceGroup -ResourceGroupName SqlRecoveryRG -Location 'WestEurope'

  'Create Azure subnet...' #| Write-Verbose  # Microsoft.Azure.Commands.Network.Models.PSSubnet
  $subnetConfig = New-AzureRmVirtualNetworkSubnetConfig `
    -Name SqlRecoverySubnet `
    -AddressPrefix 192.168.1.0/24
  'Create Azure virtual network...' #| Write-Verbose
  $vnet = New-AzureRmVirtualNetwork `
    -ResourceGroupName $ResourceGroupName `
    -Location 'WestEurope' `
    -Name SqlRecoveryVnet `
    -AddressPrefix 192.168.0.0/16 `
    -Subnet $subnetConfig
  'Create Azure public IP address...' #| Write-Verbose
  $pip = New-AzureRmPublicIpAddress `
    -ResourceGroupName $ResourceGroupName `
    -Location 'WestEurope' `
    -AllocationMethod Static `
    -Name myPublicIPAddress
  'Create Azure network interface card (NIC)...' #| Write-Verbose
  $nic = New-AzureRmNetworkInterface `
    -ResourceGroupName $ResourceGroupName `
    -Location 'WestEurope' `
    -Name myNic `
    -SubnetId $vnet.Subnets[0].Id `
    -PublicIpAddressId $pip.Id

  'Create Azure Network Security Group (NSG):'
  'Create Azure security rule...'
  $nsgRule = New-AzureRmNetworkSecurityRuleConfig `
    -Name myNSGRule `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1000 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 3389 `
    -Access Allow
  'Create Azure Network Security Group...'
  $nsg = New-AzureRmNetworkSecurityGroup `
    -ResourceGroupName myResourceGroupVM `
    -Location EastUS `
    -Name myNetworkSecurityGroup `
    -SecurityRules $nsgRule
  'Add NSG to the subnet...'
  Set-AzureRmVirtualNetworkSubnetConfig `
    -Name SqlRecoverySubnet `
    -VirtualNetwork $vnet `
    -NetworkSecurityGroup $nsg `
    -AddressPrefix 192.168.1.0/24
  'Update Azure virtual network...'
  Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
  '/NSG created.'

  'Create Azure virtual machine:'
  'Get credentials for admin on vm...'
  $cred = Get-Credential
  'Create initial configuration...'
  $vm = New-AzureRmVMConfig -VMName myVM -VMSize Standard_DS2
  'Add OS information...'
  $vm = Set-AzureRmVMOperatingSystem `
    -VM $vm `
    -Windows `
    -ComputerName myVM `
    -Credential $cred `
    -ProvisionVMAgent -EnableAutoUpdate
  'Add image information...'
  $vm = Set-AzureRmVMSourceImage `
    -VM $vm `
    -PublisherName MicrosoftWindowsServer `
    -Offer WindowsServer `
    -Skus 2016-Datacenter `
    -Version latest
  'Add OS disk settings...'
  $vm = Set-AzureRmVMOSDisk `
    -VM $vm `
    -Name myOsDisk `
    -DiskSizeInGB 128 `
    -CreateOption FromImage `
    -Caching ReadWrite
  'Add NIC...'
  $vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
  'Create virtual machine...'
  New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $LocationName -VM $vm
  '/vm created.'

  #ToDo: Install SSDB (w/DSC)
}

End {
  $mywatch.Stop()
  [string]$Message = "New-AzureVmExample finished with success. Duration = $($mywatch.Elapsed.ToString()). [hh:mm:ss.ddd]"
  "{0:s}Z  $Message" -f [System.DateTime]::UtcNow | Write-Output
}
}  # New-AzureVmExample()


function New-AzureVmExample02 {
<#
.DESCRIPTION
  Sandbox for basic virtual SQL Server Database Engine server in Azure
.LINK
  Microsoft Docs: Create and Manage Windows VMs with the Azure PowerShell module
  https://docs.microsoft.com/en-us/azure/virtual-machines/windows/tutorial-manage-vm
.NOTES
  2017-08-04  (Niels Grove-Rasmussen) Function created to implement sandbox inspired from Microsoft tutorial.
  2017-08-04  Test use static defined variables when create Azure Resource Group
  2017-08-04T08:42:05Z  New-AzureVmExample finished with success. Duration = 00:07:57.7643095.
  2017-08-04  Test static defined variables when create Azure virtual network
  2017-08-04T09:01:44Z  New-AzureVmExample finished with success. Duration = 00:07:01.8293045.
  2017-08-04T09:35:34Z  New-AzureVmExample finished with success. Duration = 00:07:43.9227476.
  2017-08-04  Test static defined variables when creating Azure virtual machine
  2017-08-04T09:58:22Z  New-AzureVmExample finished with success. Duration = 00:13:48.7982498.
  2017-08-04  Test static defined variable on dynamic example when create Azure Resource Group
  2017-08-04T10:12:58Z  New-AzureVmExample finished with success. Duration = 00:12:39.6250603.
  2017-08-04  Test (partly) dynamic defined variable when create Azure Resource Group
  2017-08-04T10:31:50Z  New-AzureVmExample finished with success. Duration = 00:12:09.1518720.
  2017-08-04T10:47:03Z  New-AzureVmExample finished with success. Duration = 00:10:29.6620053.
  2017-08-04  Test with very long variable name for virtual machine name.
  2017-08-04T11:02:13Z  New-AzureVmExample finished with success. Duration = 00:09:38.3898728.
  2017-08-04  Test with variable in userdefined object for virtual machine name.
  2017-08-04T11:30:41Z  New-AzureVmExample finished with success. Duration = 00:14:17.5418096.
  2017-08-04T11:43:31Z  New-AzureVmExample finished with success. Duration = 00:09:43.8574152.
#>
[CmdletBinding()]
[OutputType([void])]
Param()

Begin {
  $mywatch = [System.Diagnostics.Stopwatch]::StartNew()
  "{0:s}Z  ::  New-AzureVmExample" -f [System.DateTime]::UtcNow | Write-Verbose

  Import-Module -Name AzureRM

  Get-Module AzureRM

  'Log in to Azure...'
  Login-AzureRmAccount
}

Process {
  'Create Azure Resource Group identifier...' #| Write-Verbose
  # 48..59  : cifres 0 (zero) to 9 in ASCII
  # 65..90  : Uppercase letters in ASCII
  # 97..122 : Lowercase letters in ASCII
  [string]$AzureRgId = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 11 | ForEach-Object {[char]$_})
  #[string]$AzureRgId = '1QaZ2WsX3Edc' # Static value for testing without autogenerated resource group id - OK
  "  Azure Resource Group ID = '$AzureRgId'." #| Write-Verbose

  'Setting variables with common values...' #| Write-Verbose
  #[string]$ResourceGroupName = 'RecoveryRG'  # OK
  #[string]$ResourceGroupName = 'RG_1QaZ2WsX3Ed'  # OK
  [string]$ResourceGroupName = 'RG_' + $AzureRgId
  "  Azure Resource Group name = '$ResourceGroupName'."
  [string]$LocationName = 'WestEurope'
  [string]$SubnetName = 'RecoverySubnet'
  [string]$VNetName = 'RecoveryVNet'
  [string]$NicName = 'RecoveryNic'
  [string]$NsgName = 'RecoveryNsg'
  [string]$PublicIpName = 'RecoveryPublicIp'
  #[string]$vmName = 'RecoveryVM'  # OK
  #[string]$vmNameWithVeryLongVariableName = 'RecoveryVM'  # OK
  [string]$OsDiskName = 'RecoveryOsDisk'

  [PSObject]$AzureVm = New-Object -TypeName PSObject -Property (@{
    ResourceGroupName = 'RecoveryRG_' + $AzureRgId;
    LocationName = 'WestEurope';
    SubnetName = 'Subnet_' + $AzureRgId;
    PublicIpAddressName= 'PublicIp_' + $AzureRgId;
    NicName = 'Nic_' + $AzureRgId;
    NsgRuleName = 'NsgRule_' + $AzureRgId;
    NsgName = 'Nsg_' + $AzureRgId;
    DiskName = 'OsDisk_' + $AzureRgId;
    NameWithLongVariableName = 'RecoveryVM'
  })
  $AzureVm.PSObject.TypeNames.Insert(0, 'Vm.Azure')

  'Create Azure resource group...' #| Write-Verbose
  New-AzureRmResourceGroup -ResourceGroupName $ResourceGroupName -Location $LocationName

  'Create Azure subnet...' #| Write-Verbose
  $subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix 192.168.1.0/24
  'Create Azure virtual network...' #| Write-Verbose
  $vnet = New-AzureRmVirtualNetwork `
    -ResourceGroupName $ResourceGroupName `
    -Location $LocationName `
    -Name $VNetName `
    -AddressPrefix 192.168.0.0/16 `
    -Subnet $subnetConfig
  'Create Azure public IP address...' #| Write-Verbose
  $pip = New-AzureRmPublicIpAddress `
    -ResourceGroupName $ResourceGroupName `
    -Location $LocationName `
    -AllocationMethod Static `
    -Name $PublicIpName
  'Create Azure network interface card (NIC)...' #| Write-Verbose
  $nic = New-AzureRmNetworkInterface `
    -ResourceGroupName $ResourceGroupName `
    -Location $LocationName `
    -Name $NicName `
    -SubnetId $vnet.Subnets[0].Id `
    -PublicIpAddressId $pip.Id

  'Create Azure Network Security Group (NSG):'
  '  Create Azure security rule...'
  $nsgRule = New-AzureRmNetworkSecurityRuleConfig `
    -Name myNSGRule `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1000 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 3389 `
    -Access Allow
  '  Create Azure Network Security Group...'
  $nsg = New-AzureRmNetworkSecurityGroup `
    -ResourceGroupName $ResourceGroupName `
    -Location $LocationName `
    -Name $NsgName `
    -SecurityRules $nsgRule
  '  Add NSG to the subnet...'
  Set-AzureRmVirtualNetworkSubnetConfig `
    -Name $SubnetName `
    -VirtualNetwork $vnet `
    -NetworkSecurityGroup $nsg `
    -AddressPrefix 192.168.1.0/24
  '  Update Azure virtual network...'
  Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
  '/NSG created.'

  'Get credentials for admin on vm...'
  $cred = Get-Credential

  'Create Azure virtual machine:'
  '  Create initial configuration...'
  #$vm = New-AzureRmVMConfig -VMName $vmName -VMSize Standard_D1
  #"  Virtual machine name = '$vmNameWithVeryLongVariableName'."
  #$vm = New-AzureRmVMConfig -VMName $vmNameWithVeryLongVariableName -VMSize Standard_D1
  "  Virtual machine name = '$($AzureVm.NameWithLongVariableName)'."
  $vm = New-AzureRmVMConfig -VMName $AzureVm.NameWithLongVariableName -VMSize Standard_D1
  '  Add OS information...'
  $vm = Set-AzureRmVMOperatingSystem `
    -VM $vm `
    -Windows `
    -ComputerName $AzureVm.NameWithLongVariableName `
    -Credential $cred `
    -ProvisionVMAgent -EnableAutoUpdate
  '  Add image information...'
  $vm = Set-AzureRmVMSourceImage `
    -VM $vm `
    -PublisherName MicrosoftWindowsServer `
    -Offer WindowsServer `
    -Skus 2016-Datacenter `
    -Version latest
  '  Add OS disk settings...'
  $vm = Set-AzureRmVMOSDisk `
    -VM $vm `
    -Name $OsDiskName `
    -DiskSizeInGB 128 `
    -CreateOption FromImage `
    -Caching ReadWrite
  '  Add NIC...'
  $vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
  '  Create virtual machine...'
  New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $LocationName -VM $vm
  '/Azure virtual machine created.'

  #ToDo: Install SSDB (w/DSC)
}

End {
  $mywatch.Stop()
  [string]$Message = "New-AzureVmExample finished with success. Duration = $($mywatch.Elapsed.ToString()). [hh:mm:ss.ddd]"
  "{0:s}Z  $Message" -f [System.DateTime]::UtcNow | Write-Output
}
}  # New-AzureVmExample()

###  INVOKE  ###

Clear-Host

#New-AzureVmExample01 -Verbose #-Debug

New-AzureVmExample02 -Verbose #-Debug
