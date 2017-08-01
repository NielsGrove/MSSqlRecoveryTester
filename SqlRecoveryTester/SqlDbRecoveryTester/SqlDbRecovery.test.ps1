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

#Requires -Version 5
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
  2017-08-01  (Niels Grove-Rasmussen) Function can create one Azure vm wo/SSDB. Can begin parameterisation.
#>
[CmdletBinding()]
[OutputType([void])]
Param(
  #[Parameter(Mandatory=$true, ValueFromPipeLine=$true,HelpMessage='Take your time to write a good help message...')]
  #[string]$param1
)

Begin {
  $mywatch = [System.Diagnostics.Stopwatch]::StartNew()
  "{0:s}Z  ::  NewAzureSsdb( '<param1>' )" -f [System.DateTime]::UtcNow | Write-Verbose

  Import-Module -Name AzureRM

  'Test AzureRM module import...' | Write-Verbose
  $AzureRM = Get-Module AzureRM
  if ($AzureRM)
  { 'OK - PowerShell module AzureRM is imported.' | Write-Verbose }
  else
  { throw 'PowerShell module AzureRM is NOT imported!' }

  #ToDo: Test Azure login
  'Log in to Azure...' | Write-Verbose
  Login-AzureRmAccount
}

Process {
  'Create Azure Resource Group identifier...' | Write-Verbose
  [string]$AzureRgId = "0:yyyyMMdd'T'HHmmss'Z'" -f [System.DateTime]::UtcNow
  "Azure Resource Group ID = '$AzureRgId'." | Write-Verbose

  'Setting variables with common values...' | Write-Verbose
  [string]$ResourceGroupName = 'SqlRecoveryRG_' + $AzureRgId
  [string]$LocationName = 'WestEurope'
  [string]$SubnetName = 'Subnet_' + $AzureRgId
  [string]$PublicIpAddressName = 'PublicIp_' + $AzureRgId
  [string]$NicName = 'Nic_' + $AzureRgId
  [string]$NsgRuleName = 'NsgRule_' + $AzureRgId
  [string]$NsgName = 'Nsg_' + $AzureRgId
  [string]$DiskName = 'OsDisk_' + $AzureRgId
  [string]$vmName = 'VM_' + $AzureRgId

  'Test if Azure resource group exists...' | Write-Verbose
  #ToDo: Test Azure resource group

  'Create Azure resource group...' | Write-Verbose
  New-AzureRmResourceGroup -ResourceGroupName SqlRecoveryRG -Location 'WestEurope'

  'Create Azure subnet...' | Write-Verbose  # Microsoft.Azure.Commands.Network.Models.PSSubnet
  $subnetConfig = New-AzureRmVirtualNetworkSubnetConfig `
    -Name $SubnetName `
    -AddressPrefix 192.168.1.0/24
  'Create Azure virtual network...' | Write-Verbose
  $vnet = New-AzureRmVirtualNetwork `
    -ResourceGroupName $ResourceGroupName `
    -Location $LocationName `
    -Name SqlRecoveryVnet `
    -AddressPrefix 192.168.0.0/16 `
    -Subnet $subnetConfig
  'Create Azure public IP address...' | Write-Verbose
  $pip = New-AzureRmPublicIpAddress `
    -ResourceGroupName $ResourceGroupName `
    -Location $LocationName `
    -AllocationMethod Static `
    -Name $PublicIpAddressName
  'Create Azure network interface card (NIC)...' | Write-Verbose
  $nic = New-AzureRmNetworkInterface `
    -ResourceGroupName $ResourceGroupName `
    -Location $LocationName `
    -Name $NicName `
    -SubnetId $vnet.Subnets[0].Id `
    -PublicIpAddressId $pip.Id

  'Create Azure Network Security Group (NSG):' | Write-Verbose
  'Create Azure security rule...' | Write-Verbose
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
  'Create Azure Network Security Group...' | Write-Verbose
  $nsg= New-AzureRmNetworkSecurityGroup `
    -ResourceGroupName $ResourceGroupName `
    -Location $LocationName `
    -Name $NsgName `
    -SecurityRules $nsgRule
  'Add NSG to subnet...' | Write-Verbose
  Set-AzureRmVirtualNetworkSubnetConfig `
    -Name $SubnetName `
    -VirtualNetwork $vnet `
    -NetworkSecurityGroup $nsg `
    -AddressPrefix 192.168.1.0/24
  'Update Azure virtual network...' | Write-Verbose
  Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
  '/NSG created.' | Write-Verbose

  'Create Azure virtual machine:' | Write-Verbose
  'Get credentials for admin on vm...' | Write-Verbose
  $cred = Get-Credential
  'Create initial configuration...' | Write-Verbose
  $vm = New-AzureRmVMConfig `
    -VMName $vmName `
    -VMSize Standard_DS2
  'Add OS information...' | Write-Verbose
  $vm = Set-AzureRmVMOperatingSystem `
    -VM $vm `
    -Windows `
    -ComputerName $vmName `
    -Credential $cred `
    -ProvisionVMAgent -EnableAutoUpdate
  'Add image information...' | Write-Verbose
  $vm = Set-AzureRmVMSourceImage `
    -VM $vm `
    -PublisherName MicrosoftWindowsServer `
    -Offer WindowsServer `
    -Skus 2016-Datacenter `
    -Version latest
  'Add OS disk settings...' | Write-Verbose
  $vm = Set-AzureRmVMOSDisk `
    -VM $vm `
    -Name $DiskName `
    -DiskSizeInGB 128 `
    -CreateOption FromImage `
    -Caching ReadWrite
  'Add NIC...' | Write-Verbose
  $vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
  'Create virtual machine...' | Write-Verbose
  New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $LocationName -VM $vm
  '/virtual machine created.' | Write-Verbose

  #ToDo: Install SSDB (w/DSC)
}

End {
  $mywatch.Stop()
  [string]$Message = "New-AzureSsdb finished with success. Duration = $($mywatch.Elapsed.ToString()). [hh:mm:ss.ddd]"
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
New-AzureSsdb -Verbose #-Debug
