# =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
#       Script: PatchSPD2013.ps1
#
#       Author: Critical Path Training, LLC
#               http://www.CriticalPathTraining.com
#
#  Description: Adds a few registry keys to the virtual machine to fix an issue with 
#                   SharePoint Designer 2013 Beta 2 / Preview where it can't create BCS External Content Types.
# =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=

$ErrorActionPreference = 'Stop'

Write-Host
Write-Host "Patching SharePoint Designer 2013" -ForegroundColor White
Write-Host



function VerifyRegistryPath ([string]$path,[bool]$createIfMissing) {
  Write-Host "    .. checking for key: $path" -ForegroundColor Gray
  if (Test-Path "Registry::$path") {
    Write-Host "    Registry key exists: " + $path -ForegroundColor Gray
  } else {
    Write-host "    .. key not found.." -ForegroundColor Gray
	Write-Host "    .. creating key: $path" -ForegroundColor Gray
    $key = New-Item -Path $path -ItemType Directory
    Write-Host "    Created key: " $path -ForegroundColor Gray
  }
}

Write-Host
Write-Host "(1) Adding Registry Keys..." -ForegroundColor White
Write-Host "    .. adding key: HKLM\SOFTWARE\Microsoft\StrongName\Verification\*,71e9bce111e9429c" -ForegroundColor Gray
VerifyRegistryPath "HKLM:\SOFTWARE\Microsoft\StrongName" $true
VerifyRegistryPath "HKLM:\SOFTWARE\Microsoft\StrongName\Verification" $true
VerifyRegistryPath "HKLM:\SOFTWARE\Microsoft\StrongName\Verification\*,71e9bce111e9429c" $true
Write-Host "    Key added" -ForegroundColor Gray
Write-Host "    .. adding key: HKLM\SOFTWARE\Microsoft\StrongName\Verification\*,71e9bce111e9429c" -ForegroundColor Gray
VerifyRegistryPath "HKLM:\SOFTWARE\Microsoft\StrongName\Verification\*,*" $true
Write-Host "    Key added" -ForegroundColor Gray

Write-Host "    .. adding key: HKLM\SOFTWARE\Wow6432Node\Microsoft\StrongName\Verification\*,71e9bce111e9429c" -ForegroundColor Gray
VerifyRegistryPath "HKLM:\SOFTWARE\Wow6432Node\Microsoft\StrongName" $true
VerifyRegistryPath "HKLM:\SOFTWARE\Wow6432Node\Microsoft\StrongName\Verification" $true
VerifyRegistryPath "HKLM:\SOFTWARE\Wow6432Node\Microsoft\StrongName\Verification\*,71e9bce111e9429c" $true
Write-Host "    Key added" -ForegroundColor Gray
Write-Host "    .. adding key: HKLM\SOFTWARE\Wow6432Node\Microsoft\StrongName\Verification\*,*" -ForegroundColor Gray
VerifyRegistryPath "HKLM:\SOFTWARE\Wow6432Node\Microsoft\StrongName\Verification\*,*" $true
Write-Host "    Key added" -ForegroundColor Gray


Write-Host "(2) Verify Windows Installer Service is not Running..." -ForegroundColor White
$installerService = Get-Service -Name msiserver
Write-Host "    .. shutting Down Windows Installer Service..." -ForegroundColor Gray
if ($installerService.Status -eq "Stopped"){
  Start-Service -Name msiserver
  Write-Host "    Windows Installer Service Stopped" -ForegroundColor Gray
}


Write-Host 
Write-Host "Registry keys added for to fix SharePoint Designer 2013 bug" -ForegroundColor Green
Write-Host