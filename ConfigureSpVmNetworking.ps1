# =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
#       Script: ConfigureSpVmNetworking.ps1
#
#       Author: Critical Path Training, LLC
#               http://www.CriticalPathTraining.com
#
#  Description: Configures the specified NIC for SharePoint.
#
#   Parameters: $TargetEnvironment - Role of the server being configured (ie: DC | ALLUP).
#               $InternNicName - Name of the internal NIC (ie: Internal LAN).
#               $ExternalNicName - Name of the external NIC (ie: External LAN).
#
#  Optional Parameters:
#               $ServerDCStaticIp - IP of the server on the internal LAN.
#                          Default = "192.168.150.102"
#               $ServerAllUpStaticIp - IP of the server on the external LAN.
#                          Default = "192.168.150.103"
# =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=

param(
	[string]$TargetEnvironment = $(Read-Host("Enter the server to configure: (ie: DC | ALLUP)")),
	[string]$InternNicName = $(Read-Host("Enter the name of the internal NIC (ie: Internal LAN)")),
	[string]$ExternalNicName = $(Read-Host("Enter the name of the external NIC (ie: External LAN)")),
	[string]$ServerDCStaticIp = "192.168.150.102",
	[string]$ServerAllUpStaticIp = "192.168.150.103"
)

$ErrorActionPreference = 'Stop'
$TcpIpV4SubnetMask = "255.255.255.0"

Write-Host
Write-Host "Configuring Networking for SharePoint 2013 Virtual Environment" -ForegroundColor White
Write-Host " Script Steps:" -ForegroundColor White
Write-Host " (0) Validating parameters..." -ForegroundColor White
Write-Host " (1) Configuring Internal NIC..." -ForegroundColor White
Write-Host " (2) Configuring External NIC..." -ForegroundColor White
Write-Host

#
# verify parameters passed in
#
Write-Host "(0) Validating parameters..." -ForegroundColor White
# envrionemtn type
if ($TargetEnvironment -eq $null -xor $TargetEnvironment -eq ""){
	Write-Error '$TargetEnvironment is required'
	Exit
} else { 
  if ( ($TargetEnvironment -ne "DC") -and ($TargetEnvironment -ne "ALLUP") ){
    Write-Error '$TargetEnvironment must be either "DC" (Domain Controller) or "ALLUP" (All-Up Server).'
  }
}
# internal NIC name
if ($InternNicName -eq $null -xor $InternNicName -eq ""){
	Write-Error '$InternNicName is required'
	Exit
}
# external NIC name
if ($ExternalNicName -eq $null -xor $ExternalNicName -eq ""){
	Write-Error '$ExternalNicName is required'
	Exit
}

Write-Host
Write-Host "(1) Configuring Internal NIC..." -ForegroundColor White
$internalLanNicAdapter = Get-WmiObject Win32_NetworkAdapter | 
  Where-Object {$_.NetConnectionID -eq $InternNicName}
$internalLanNicConfig = Get-WmiObject Win32_NetworkAdapterConfiguration | 
  Where-Object {$_.InterfaceIndex -eq $internalLanNicAdapter.InterfaceIndex}
Write-Host "    Obtained Reference to Internal NIC" -ForegroundColor Gray 

# determine the IP to set
if ($TargetEnvironment -eq "DC") {
  $StaticIpToSet = $ServerDCStaticIp
} else {
  $StaticIpToSet = $ServerAllUpStaticIp
}

Write-Host "    .. setting TCP/IPv4 configuration..." -ForegroundColor Gray 
$silence = $internalLanNicConfig.EnableStatic($StaticIpToSet,$TcpIpV4SubnetMask)
$silence = $internalLanNicConfig.SetGateways($ServerDCStaticIp)
$silence = $internalLanNicConfig.SetDNSServerSearchOrder($ServerDCStaticIp)
Write-Host "    Internal NIC TCP/IPv4 Configuration Complete!" -ForegroundColor Green


Write-Host
Write-Host "(2) Configuring External NIC..." -ForegroundColor White
$externalLanNicAdapter = Get-WmiObject Win32_NetworkAdapter | 
  Where-Object {$_.NetConnectionID -eq $ExternalNicName}
$externalLanNicConfig = Get-WmiObject Win32_NetworkAdapterConfiguration | 
  Where-Object {$_.InterfaceIndex -eq $externalLanNicAdapter.InterfaceIndex}
Write-Host "    Obtained Reference to External NIC" -ForegroundColor Gray 

Write-Host "    .. setting TCP/IPv4 configuration..." -ForegroundColor Gray 
$silence = $externalLanNicConfig.EnableDHCP()
$silence = $externalLanNicConfig.SetDynamicDNSRegistration($false)
$silence = $externalLanNicConfig.SetWINSServer($ServerDCStaticIp,"")
Write-Host "    External NIC TCP/IPv4 Configuration Complete!" -ForegroundColor Green

Write-Host 
Write-Host "Finished configuring NICs!" -ForegroundColor Green
