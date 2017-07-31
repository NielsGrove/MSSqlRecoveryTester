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
  TechNet Library: about_Functions_Advanced
  https://technet.microsoft.com/en-us/library/dd315326.aspx
#>

#Requires -Version 4
Set-StrictMode -Version Latest


#region infrastructure

<#
*) Create blob storage for backup file(-s)
   +) Create Azure Storage Account: Cool access tier
      (https://docs.microsoft.com/en-us/azure/storage/storage-create-storage-account)
*) Create virtual server for SSDB
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

