<#
.DESCRIPTION
  Testing functions in module "SqlDbRecovery.psm1".
.PARAMETER <Parameter Name>
  (none)
.EXAMPLE
.INPUTS
.OUTPUTS
.RETURNVALUE

.NOTES
  Filename  : SqlDbRecovery.test.ps1
.NOTES
  2017-07-31  (Niels Grove-Rasmussen) File created to investigate project file structure.

.LINK
  TechNet Library: about_Functions_Advanced
  https://technet.microsoft.com/en-us/library/dd315326.aspx
#>

#Requires -Version 4
Set-StrictMode -Version Latest

#Import-Module E:\GitHub\MSSqlRecoveryTester\SqlRecoveryTester\SqlDbRecoveryTester\SqlDbRecovery.psm1


#region infrastructure

function New-AzureSsdb {
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
#>
[CmdletBinding()]
[OutputType([void])]
Param(
  #[Parameter(Mandatory=$true, ValueFromPipeLine=$true,HelpMessage='Take your time to write a good help message...')]
  #[string]$param1
)

Begin {
  $mywatch = [System.Diagnostics.Stopwatch]::StartNew()
  "{0:s}Z  ::  Verb-Noun( '$param1' )" -f [System.DateTime]::UtcNow | Write-Verbose

  Import-Module -Name AzureRM

  #ToDo: Test AzureRM module
  Get-Module AzureRM

  #ToDo: Test Azure login
  'Log in to Azure...'
  Login-AzureRmAccount
}

Process {
  'Setting variables with common values...' #| Write-Verbose
  [string]$ResourceGroupName = 'SqlRecoveryRG'
  [string]$LocationName = 'WestEurope'
  [string]$SubnetName = 'SqlRecoverySubnet'
  [string]$PublicIpAddressName = 'SqlRecoveryIp'
  [string]$NicName = 'SqlRecoveryNic'
  [string]$NsgRuleName = 'SqlRecoveryNsgRule'
  [string]$DiskName = 'SqlRecoveryOsDisk'
  [string]$vmName = 'SqlRecoveryVM'

  'Create Azure resource group...' #| Write-Verbose
  New-AzureRmResourceGroup -ResourceGroupName SqlRecoveryRG -Location 'WestEurope'

  'Create Azure subnet...' #| Write-Verbose  # Microsoft.Azure.Commands.Network.Models.PSSubnet
  $subnetConfig = New-AzureRmVirtualNetworkSubnetConfig `
    -Name $SubnetName `
    -AddressPrefix 192.168.1.0/24
  'Create Azure virtual network...' #| Write-Verbose
  $vnet = New-AzureRmVirtualNetwork `
    -ResourceGroupName $ResourceGroupName `
    -Location $LocationName `
    -Name SqlRecoveryVnet `
    -AddressPrefix 192.168.0.0/16 `
    -Subnet $subnetConfig
  'Create Azure public IP address...' #| Write-Verbose
  $pip = New-AzureRmPublicIpAddress `
    -ResourceGroupName $ResourceGroupName `
    -Location $LocationName `
    -AllocationMethod Static `
    -Name $PublicIpAddressName
  'Create Azure network interface card (NIC)...' #| Write-Verbose
  $nic = New-AzureRmNetworkInterface `
    -ResourceGroupName $ResourceGroupName `
    -Location $LocationName `
    -Name $NicName `
    -SubnetId $vnet.Subnets[0].Id `
    -PublicIpAddressId $pip.Id

  'Create Azure Network Security Group (NSG):'
  'Create Azure security rule...'
  $nsgRule = New-AzureRmNetworkSecurityRuleConfig `
    -Name $NsgRuleName `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1000 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 3389 `
    -Access Allow
  'Create Azure Network Security Group...'
  Set-AzureRmVirtualNetworkSubnetConfig `
    -Name $SubnetName `
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
  $vm = New-AzureRmVMConfig -VMName $vmName -VMSize Standard_DS2
  'Add OS information...'
  $vm = Set-AzureRmVMOperatingSystem `
    -VM $vm `
    -Windows `
    -ComputerName $vmName `
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
    -Name $DiskName `
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
  [string]$Message = "<function> finished with success. Duration = $($mywatch.Elapsed.ToString()). [hh:mm:ss.ddd]"
  "{0:s}Z  $Message" -f [System.DateTime]::UtcNow | Write-Output
}
}  # New-AzureSsdb()


#endregion infrastructure


#region SqlDb

function Verb-Noun {
<#
.DESCRIPTION
  <Description of the function>
.PARAMETER <Name>
  <parameter description>
.OUTPUTS
  (none)
.RETURNVALUE
  (none)
.LINK
  <link to external reference or documentation>
.NOTES
  <timestamp> <version>  <initials> <version changes and description>
#>
[CmdletBinding()]
[OutputType([void])]
Param(
  [Parameter(Mandatory=$true, ValueFromPipeLine=$true,HelpMessage='Take your time to write a good help message...')]
  [string]$param1
)

Begin {
  $mywatch = [System.Diagnostics.Stopwatch]::StartNew()
  "{0:s}Z  ::  Verb-Noun( '$param1' )" -f [System.DateTime]::UtcNow | Write-Verbose
}

Process {
}

End {
  $mywatch.Stop()
  [string]$Message = "<function> finished with success. Duration = $($mywatch.Elapsed.ToString()). [hh:mm:ss.ddd]"
  "{0:s}Z  $Message" -f [System.DateTime]::UtcNow | Write-Output
}
}  # Verb-Noun()

#endregion SqlDb


###  INVOKE  ###

Clear-Host
#<function call> -Verbose -Debug