# =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
#       Script: AddDisableLoopbackCheckRegKey.ps1
#
#       Author: Critical Path Training, LLC
#               http://www.CriticalPathTraining.com
#
#  Description: Creates a registry key DisableLoopbackCheck as outlined in 
#                 MSFT KB http://support.microsoft.com/kb/896861
# =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=

Write-Host
Write-Host "Disabling internal loopback check for accessing host header sites" -ForegroundColor White
Write-Host

$regKeyPath = "HKLM:\System\CurrentControlSet\Control\Lsa"
$key = "DisableLoopbackCheck"

if (Test-Path $regKeyPath){
	$keyValue = (Get-ItemProperty $regKeyPath).$key
	if ($keyValue -ne $null){
		Write-Host "    .. setting key $regKeyPath\$key=1" -ForegroundColor Gray
		Set-ItemProperty -Path $regKeyPath -Name $key -Value "1"
	} else {
		Write-Host "    .. creating & setting key $regKeyPath\$key=1" -ForegroundColor Gray
		$disableLoopbackCheckKey = New-ItemProperty -Path $regKeyPath -Name $key -Value "1" -PropertyType dword
	}
} else {
	Write-Host "    .. creating & setting key $regKeyPath\$key=1" -ForegroundColor Gray
	$disableLoopbackCheckKey = New-ItemProperty -Path $regKeyPath -Name $key -Value "1" -PropertyType dword
}

Write-Host 
Write-Host "Registry Key Created!" -ForegroundColor Green
Write-Host