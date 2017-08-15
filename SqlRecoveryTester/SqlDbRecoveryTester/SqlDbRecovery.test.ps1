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

function New-AzureVm {
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
  2017-08-02  (Niels Grove-Rasmussen) Function renamed to New-AzureVm. SSDB or other application installation will be in seperate functions.
  2017-08-03  (Niels Grove-Rasmussen) Dynamic resource group name for scalability. Existince of RG test added.
  2017-08-09  (Niels Grove-Rasmussen) Stop and Deallocate virtual machine added.
#>
[CmdletBinding()]
[OutputType([void])]
Param(
  #[Parameter(Mandatory=$true, ValueFromPipeLine=$true,HelpMessage='Take your time to write a good help message...')]
  #[string]$param1
)

Begin {
  $mywatch = [System.Diagnostics.Stopwatch]::StartNew()
  "{0:s}Z  ::  New-AzureVm()" -f [System.DateTime]::UtcNow | Write-Verbose

  Import-Module -Name AzureRM

  'Test AzureRM module import...' | Write-Verbose
  $AzureRM = Get-Module AzureRM
  if ($AzureRM)
  { 'OK - PowerShell module AzureRM is imported.' | Write-Verbose }
  else
  { throw 'PowerShell module AzureRM is NOT imported!' }

  'Test if already logged in Azure...' | Write-Verbose
  try
  { $AzureContext = Get-AzureRmContext -ErrorAction Continue }
  catch [System.Management.Automation.PSInvalidOperationException] {
    'Log in to Azure...' | Write-Verbose
    $AzureContext = Login-AzureRmAccount
  }
  catch
  { throw $_.Exception }
  if ($AzureContext.Account -eq $null) {
    'Log in to Azure...' | Write-Verbose
    $AzureContext = Login-AzureRmAccount
  }
  else
  { "OK - Logged in Azure as '$($AzureContext.Account)'." | Write-Verbose }
}

Process {
  'Create Azure Resource Group identifier...' | Write-Verbose
  # 48..59  : cifres 0 (zero) to 9 in ASCII
  # 65..90  : Uppercase letters in ASCII
  # 97..122 : Lowercase letters in ASCII
  [string]$AzureRgId = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 11 | ForEach-Object {[char]$_})
  "Azure Resource Group ID = '$AzureRgId'." | Write-Verbose

  'Setting variables with common values...' | Write-Verbose
  [psobject]$AzureVm = New-Object -TypeName PSObject -Property (@{
    ResourceGroupName = 'TesterRG_' + $AzureRgId;
    LocationName = 'WestEurope';
    SubnetName = 'TesterSubnet';
    PublicIpAddressName= 'TesterPublicIp';
    NicName = 'TesterNic';
    NsgRuleName = 'TesterNsgRule';
    NsgName = 'TesterNsg';
    OsDiskName = 'TesterOsDisk';
    Name = 'TesterVM'
  })
  $AzureVm.PSObject.TypeNames.Insert(0, 'Vm.Azure')

  'Test if Azure resource group exists...' | Write-Verbose
  Get-AzureRmResourceGroup -Name RG_Static -ErrorVariable NotPresent -ErrorAction SilentlyContinue
  if ($NotPresent)
  { "OK - Azure resource group '$($AzureVm.ResourceGroupName)' does not exist." | Write-Verbose }
  else
  { throw "The Azure resource group '$($AzureVm.ResourceGroupName)' does already exist." }
  "{0:s}Z  Create Azure resource group '$($AzureVm.ResourceGroupName)'..." -f [System.DateTime]::UtcNow | Write-Verbose
  $RgTags = @{ MS_Description = 'Really good prose description.'; PFA_System = 'mitPFA' }
  $AzureResourceGroup = New-AzureRmResourceGroup -Name $AzureVm.ResourceGroupName -Location $AzureVm.LocationName -Tag $RgTags
  if ($AzureResourceGroup.ProvisioningState -ceq 'Succeeded')
  { "OK - Azure resource group provisioning state : '$($AzureResourceGroup.ProvisioningState)'." | Write-Verbose }
  else
  { throw "Azure resource group provisioning state : '$($AzureResourceGroup.ProvisioningState)'. 'Succeeded' was expected." }

  'Create Azure subnet...' | Write-Verbose
  $subnetConfig = New-AzureRmVirtualNetworkSubnetConfig `
    -Name $AzureVm.SubnetName `
    -AddressPrefix 192.168.1.0/24
  'Create Azure virtual network...' | Write-Verbose
  $vnet = New-AzureRmVirtualNetwork `
    -ResourceGroupName $AzureVm.ResourceGroupName `
    -Location $AzureVm.LocationName `
    -Name SqlRecoveryVnet `
    -AddressPrefix 192.168.0.0/16 `
    -Subnet $subnetConfig
  'Create Azure public IP address...' | Write-Verbose
  $pip = New-AzureRmPublicIpAddress `
    -ResourceGroupName $AzureVm.ResourceGroupName `
    -Location $AzureVm.LocationName `
    -AllocationMethod Static `
    -Name $AzureVm.PublicIpAddressName
  'Create Azure network interface card (NIC)...' | Write-Verbose
  $nic = New-AzureRmNetworkInterface `
    -ResourceGroupName $AzureVm.ResourceGroupName `
    -Location $AzureVm.LocationName `
    -Name $AzureVm.NicName `
    -SubnetId $vnet.Subnets[0].Id `
    -PublicIpAddressId $pip.Id

  'Create Azure Network Security Group (NSG):' | Write-Verbose
  'Create Azure security rule...' | Write-Verbose
  $nsgRule = New-AzureRmNetworkSecurityRuleConfig `
    -Name $AzureVm.NsgRuleName `
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
    -ResourceGroupName $AzureVm.ResourceGroupName `
    -Location $AzureVm.LocationName `
    -Name $AzureVm.NsgName `
    -SecurityRules $nsgRule
  'Add NSG to subnet...' | Write-Verbose
  $AzureSubNetResult = Set-AzureRmVirtualNetworkSubnetConfig `
    -Name $AzureVm.SubnetName `
    -VirtualNetwork $vnet `
    -NetworkSecurityGroup $nsg `
    -AddressPrefix 192.168.1.0/24
  if ($AzureSubNetResult.ProvisioningState -ceq 'Succeeded')
  { "'OK - Azure subnet provisioning state : '$($AzureSubNetResult.ProvisioningState)'." | Write-Verbose }
  else
  { throw "Azure subnet provisioning state : '$($AzureSubNetResult.ProvisioningState)'. 'Succeeded' was expected." }
  'Update Azure virtual network...' | Write-Verbose
  $AzureVNetResult = Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
  if ($AzureVNetResult.ProvisioningState -ceq 'Succeeded')
  { "OK - Azure vnet provisioning state : '$($AzureVNetResult.ProvisioningState)'." | Write-Verbose }
  else
  { throw "Azure vnet provisioning state : '$($AzureVNetResult.ProvisioningState)'. 'Succeeded' was expected." }
  '/NSG created.' | Write-Verbose

  'Create Azure virtual machine:' | Write-Verbose
  $vmStopWatch = [System.Diagnostics.Stopwatch]::StartNew()
  'Get credentials for admin on vm...' | Write-Verbose
  <# ToDo : Test and loop password requirements
  New-AzureRmVM : The supplied password must be between 8-123 characters long and must satisfy at least 3 of password complexity requirements from the following: 
  1) Contains an uppercase character
  2) Contains a lowercase character
  3) Contains a numeric digit
  4) Contains a special character.
  #>
  try { $cred = Get-Credential }
  catch {
    throw $_.Exception
  }
  'Create initial configuration...' | Write-Verbose
  $vm = New-AzureRmVMConfig `
    -VMName $AzureVm.Name `
    -VMSize Standard_DS2
  'Add OS information...' | Write-Verbose
  $vm = Set-AzureRmVMOperatingSystem `
    -VM $vm `
    -Windows `
    -ComputerName $AzureVm.Name `
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
    -Name $AzureVm.OsDiskName `
    -DiskSizeInGB 128 `
    -CreateOption FromImage `
    -Caching ReadWrite
  'Add NIC...' | Write-Verbose
  $vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
  "{0:s}Z  Create virtual machine..." -f [System.DateTime]::UtcNow | Write-Verbose
  $AzureVmResult = New-AzureRmVM -ResourceGroupName $AzureVm.ResourceGroupName -Location $AzureVm.LocationName -VM $vm
  if ($AzureVmResult.StatusCode -ceq 'OK')
  { "OK - Azure vm status code : '$($AzureVmResult.StatusCode)'." | Write-Verbose }
  else
  { throw "Azure vm status code: '$($AzureVmResult.StatusCode)'. 'OK' was expected." }
  $vmStopWatch.Stop
  "{0:s}Z OK - virtual machine created. Duration = $($vmStopWatch.Elapsed.ToString()). [hh:mm:ss.ddd]" -f [System.DateTime]::UtcNow | Write-Verbose

  "{0:s}Z Stop virtual machine..." -f [System.DateTime]::UtcNow | Write-Verbose
  $StopVmResult = Stop-AzureRmVM -ResourceGroupName $AzureVm.ResourceGroupName -Name $AzureVm.Name -Force -StayProvisioned
  if ($StopVmResult.Status -ceq 'Succeeded')
  { "OK - Azure virtual machine stop status : '$($StopVmResult.Status)'." | Write-Verbose }
  else
  { throw "Azure virtual machine stop status : '$($StopVmResult.Status)'. 'Succeeded' was expected." }
  'Deallocate virtual machine...' | Write-Verbose
  $StopVmResult = Stop-AzureRmVM -ResourceGroupName $AzureVm.ResourceGroupName -Name $AzureVm.Name -Force
  if ($StopVmResult.Status -ceq 'Succeeded')
  { "OK - Azure virtual machine deallocate status : '$($StopVmResult.Status)'." | Write-Verbose }
  else
  { throw "Azure virtual machine deallocate status : '$($StopVmResult.Status)'. 'Succeeded' was expected." }


  #ToDo: Install SSDB (w/DSC) in another function
}

End {
  $mywatch.Stop()
  [string]$Message = "New-AzureVm finished with success. Duration = $($mywatch.Elapsed.ToString()). [hh:mm:ss.ddd]"
  "{0:s}Z  $Message" -f [System.DateTime]::UtcNow | Write-Output
}
}  # New-AzureVm()

#region Test

function Test-AzureVmStart {
<#
.DESCRIPTION
  Test Azure virtual machine allocation and start
.PARAMETER ResourceGroupName
  Name of Azure resource group where the virtual machine is created
.PARAMETER VirtualMachineName
  Name of the virtual machine to test.
.OUTPUTS
  (none)
.RETURNVALUE
  (none)
.LINK
  <link to external reference or documentation>
.NOTES
  2017-08-10  (Niels Grove-Rasmussen) Function created to test Allocate - Start - Stop - Deallocate of a Azure virtual machine and get some number to compare
#>
[CmdletBinding()]
[OutputType([void])]
Param(
  [Parameter(Mandatory=$true, ValueFromPipeLine=$false,HelpMessage='Name of Azure Resource Group where the virtual machine is created.')]
  [string]$ResourceGroupName,

  [Parameter(Mandatory=$true, ValueFromPipeLine=$false,HelpMessage='Name of the Azure Virtual Machine.')]
  [string]$VirtualMachineName
)

Begin {
  $mywatch = [System.Diagnostics.Stopwatch]::StartNew()
  "{0:s}Z  ::  Test-AzureVmStart( '$ResourceGroupName', 'VirtualMachineName' )" -f [System.DateTime]::UtcNow | Write-Verbose

  $CompleteMeasure = New-Object psobject
}

Process {
  "Test if resource group exists..." | Write-Verbose  # implement as parameter rule
  "  (TBD)" | Write-Verbose

  "Test if virtual machine exists..." | Write-Verbose  # implement as parameter rule
  $AzureRmVms = Get-AzureRmVM -ResourceGroupName $ResourceGroupName
  foreach ($Vm in $AzureRmVms) {
    if ($Vm.Name -ceq $VirtualMachineName)
    { "  OK - The virtual machine '$VirtualMachineName' does exist." | Write-Verbose }
    else
    { throw "The virtual machine '$VirtualMachineName' does not exist in the resource group '$ResourceGroupName'." }
  }

  "{0:s}Z  Test if virtual machine '$VirtualMachineName' is stopped and deallocated..." -f [System.DateTime]::UtcNow | Write-Verbose
  $AzureRmVmDetail = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VirtualMachineName -Status
  foreach ($VmStatus in $AzureRmVmDetail.Statuses) {
    #$VmStatus.Code | Write-Debug
    if ($VmStatus.Code -cmatch 'PowerState/(?<allocation>.*)') {
      if ($Matches['allocation'] -ceq 'deallocated')
      { "  OK - PowerState : $($Matches['allocation'])" | Write-Verbose }
      else
      { throw "The virtual machine '$VirtualachineName' is NOT stopped and deallocated. PowerState : $($Matches['allocation']). 'deallocated' expected." }
    }
  }

  #exit 42  # for test!!!
  
  "{0:s}Z  Allocate virtual machine '$VirtualMachineName'..." -f [System.DateTime]::UtcNow | Write-Verbose
  "SORRY - it is not possible to allocate and not start a virtual machine in Azure." | Write-Warning

  "{0:s}Z  Start virtual machine '$VirtualMachineName'..." -f [System.DateTime]::UtcNow | Write-Verbose
  $StartVmStopWatch = [System.Diagnostics.Stopwatch]::StartNew()
  $Result = Start-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VirtualMachineName
  if ($Result.Status -ceq 'Succeeded') {
    $StartVMStopWatch.Stop()
    "  OK - Azure virtual machine allocate status : '$($Result.Status)'." | Write-Verbose
  }
  else
  { throw "Azure virtual machine allocate status : '$($Result.Status)'. 'Succeeded' was expected." }

  "{0:s}Z  Stop virtual machine '$VirtualMachineName'..." -f [System.DateTime]::UtcNow | Write-Verbose
  $StopVmStopWatch = [System.Diagnostics.Stopwatch]::StartNew()
  $Result = Stop-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VirtualMachineName -Force -StayProvisioned
  if ($Result.Status -ceq 'Succeeded') {
    $StopVmStopWatch.Stop()
    "  OK - Azure virtual machine stop status : '$($Result.Status)'." | Write-Verbose
  }
  else
  { throw "Azure virtual machine stop status : '$($Result.Status)'. 'Succeeded' was expected." }

  "{0:s}Z  Deallocate virtual machine '$VirtualMachineName'..." -f [System.DateTime]::UtcNow | Write-Verbose
  $DeallocateVmStopWatch = [System.Diagnostics.Stopwatch]::StartNew()
  $Result = Stop-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VirtualMachineName -Force
  if ($Result.Status -ceq 'Succeeded') {
    $DeallocateVmStopWatch.Stop()
    "  OK - Azure virtual machine deallocate status : '$($Result.Status)'." | Write-Verbose
  }
  else
  { throw "Azure virtual machine deallocate status : '$($Result.Status)'. 'Succeeded' was expected." }

  $CompleteMeasure | Add-Member -NotePropertyMembers @{
    Name = 'StartVm'; $StartVmStopWatch.Elapsed
    Name = 'StopVm'; $StopVmStopWatch.Elapsed
    Name = 'DeallocateVm'; $DeallocateVmStopWatch.Elapsed
  }
}

End {
  $mywatch.Stop()
  [string]$Message = "Test-AzureVmStart finished with success. Duration = $($mywatch.Elapsed.ToString()). [hh:mm:ss.ddd]"
  "{0:s}Z  $Message" -f [System.DateTime]::UtcNow | Write-Output
}
}  # Test-AzureVmStart

#endregion Test

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

#(0..9) |  # DOES NOT WORK
#New-AzureVm -Verbose #-Debug

#New-StaticVm -Verbose #-Debug


Test-AzureVmStart -ResourceGroupName 'TesterRG_0RlkSHPsNO5' -VirtualMachineName 'TesterVM' -Verbose

#Remove-AzureRmResourceGroup -Name 'TesterRG_7WpKGqg4YMb' -Verbose #-Force

# Log out of Azure - DOES NOT WORK
#Login-AzureRmAccount -ErrorAction Stop
