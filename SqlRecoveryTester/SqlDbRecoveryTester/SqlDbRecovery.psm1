<#
.DESCRIPTION
  PowerShell module with functions for testing recovery of Microsoft SQL Server Database Engine (SSDB).
.PARAMETER <Parameter Name>
.EXAMPLE
.INPUTS
.OUTPUTS
.RETURNVALUE
.EXAMPLE

.NOTES
  Filename  : SqlDbRecovery.psm1
.NOTES
  2017-07-31  (Niels Grove-Rasmussen) File created to investigate project file structure.

.LINK
  Microsoft Docs: Azure.Storage
  https://docs.microsoft.com/en-us/powershell/module/azure.storage/
#>

#Requires -Version 4
Set-StrictMode -Version Latest


#region infrastructure

<#
*) Create blob storage for backup file(-s)
   +) Create Azure Storage Account: Standard performance tier, Cool access tier, LRS (ZRS/GRS option?)
      (https://docs.microsoft.com/en-us/azure/storage/storage-create-storage-account)
   +) Create Azure Container
      (https://docs.microsoft.com/en-us/powershell/module/azure.storage/New-AzureStorageContainer)
   +) Create Azure Blob storage
      ()
*) Create virtual server for SSDB
   (https://docs.microsoft.com/en-us/azure/virtual-machines/windows/tutorial-manage-vm)
   +) Create Azure Resource Group
      (https://docs.microsoft.com/en-us/powershell/module/azurerm.resources/new-azurermresourcegroup)
   +) Create Azure Virtual Network subnet
      (https://docs.microsoft.com/en-us/powershell/module/azurerm.network/new-azurermvirtualnetworksubnetconfig)
   +) Create Azure Virtual Network
      (https://docs.microsoft.com/en-us/powershell/module/azurerm.network/new-azurermvirtualnetwork)
   +) Create Azure public IP address
      (https://docs.microsoft.com/en-us/powershell/module/azurerm.network/new-azurermpublicipaddress)
   +) Create network interface card
      (https://docs.microsoft.com/en-us/powershell/module/azurerm.network/new-azurermnetworkinterface)
   +) Create network security group; create rule, create group, add group to subnet and update network
      (https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-nsg)
   +) Create Azure virtual machine
      
*) Install SSDB, with DSC
#>

#endregion infrastricture


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

