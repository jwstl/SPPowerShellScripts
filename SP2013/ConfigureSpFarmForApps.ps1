# =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
#       Script: ConfigureSpAppHosting.ps1
#
#       Author: Critical Path Training, LLC
#               http://www.CriticalPathTraining.com
#
#  Description: Configures a SharePoint 2013 for hosting apps. This ensures everything you need is installed, 
#                 running and configured. This is documented here: http://msdn.microsoft.com/en-us/library/fp179923(v=office.15)
# =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=

$ErrorActionPreference = 'Stop'

$appHostDomain = "apps.wingtip.com"

Write-Host
Write-Host "Configuring SharePoint Server 2013 for Hosting Apps" -ForegroundColor White
Write-Host " Script Steps:" -ForegroundColor White
Write-Host " (1) Verify SharePoint PowerShell Snapin Loaded" -ForegroundColor White
Write-Host " (2) Verifing necessary Windows Services are started..." -ForegroundColor White
Write-Host " (3) Set the SharePoint 2013 App Domain..." -ForegroundColor White
Write-Host " (4) Verifing the SharePoint App Management Service is running..." -ForegroundColor White
Write-Host " (5) Verifing the SharePoint Subscription Settings Services is running..." -ForegroundColor White
Write-Host " (6) Getting Application Pool for hosting service applications.." -ForegroundColor White
Write-Host " (7) Creating Subscription Settings Service Application.." -ForegroundColor White
Write-Host " (8) Creating App Management Service Application.." -ForegroundColor White
Write-Host " (9) Setting Tenant URL Prefix for Deployed Apps .." -ForegroundColor White
Write-Host


# Load SharePoint PowerShell snapin
Write-Host
Write-Host "(1) Verify SharePoint PowerShell Snapin Loaded" -ForegroundColor White
$snapin = Get-PSSnapin | Where-Object {$_.Name -eq 'Microsoft.SharePoint.PowerShell'}
if ($snapin -eq $null) {
	Write-Host "    ..  Loading SharePoint PowerShell Snapin" -ForegroundColor Gray
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}
Write-Host "    Microsoft SharePoint PowerShell snapin loaded" -ForegroundColor Gray 



Write-Host
Write-Host "(2) Verifing necessary Windows Services are started..." -ForegroundColor White
$adminService = Get-Service -Name spadminv4
if ($adminService.Status -eq "Running") {
  Write-Host "    SPADMINV4 service is started" -ForegroundColor Gray 
} else {
  Write-Host "    .. SPADMINV4 service not started..." -ForegroundColor Gray 
  Start-Service $adminService
  Write-Host "    SPADMINV4 service is started" -ForegroundColor Gray 
}

$timerService = Get-Service -Name sptimerv4
if ($timerService.Status -eq "Running") {
  Write-Host "    SPTIMERV4 service is started" -ForegroundColor Gray 
} else {
  Write-Host "    .. SPTIMERV4 service not started..." -ForegroundColor Gray 
  Start-Service $timerService
  Write-Host "    SPTIMERV4 service is started" -ForegroundColor Gray 
}



Write-Host
Write-Host "(3) Set the SharePoint 2013 App Domain..." -ForegroundColor White
Set-SPAppDomain $appHostDomain
Write-Host "    .. app domain '$appHostDomain' set" -ForegroundColor Gray 



Write-Host
Write-Host "(4) Verifing the SharePoint App Management Service is running..." -ForegroundColor White
$appMgmtSvcInstance = Get-SPServiceInstance | Where-Object { $_.GetType().Name -eq "AppManagementServiceInstance" }
if ($appMgmtSvcInstance.Status -ne "Online") {
  Write-Host "    .. SharePoint App Management Service is not running..." -ForegroundColor Gray 
  Write-Host "    .. starting SharePoint App Management Service..." -ForegroundColor Gray 
  $silence = Start-SPServiceInstance -Identity $appMgmtSvcInstance
  Write-Host "    SharePoint App Management Service started" -ForegroundColor Gray 
} Else {
  Write-Host "    SharePoint App Management Service is running" -ForegroundColor Gray 
}



Write-Host
Write-Host "(5) Verifing the SharePoint Subscription Settings Services is running..." -ForegroundColor White
$appSubSettingSvcInstance = Get-SPServiceInstance | Where-Object { $_.GetType().Name -eq "SPSubscriptionSettingsServiceInstance"}
if ($appSubSettingSvcInstance.Status -ne "Online") {
  Write-Host "    .. SharePoint Subscription Settings is not running..." -ForegroundColor Gray 
  Write-Host "    .. starting SharePoint Subscription Settings Service..." -ForegroundColor Gray 
  $serviceInstance = Start-SPServiceInstance -Identity $appSubSettingSvcInstance
  Write-Host "    SharePointSubscription Settings Service started" -ForegroundColor Gray 
} Else {
  Write-Host "    SharePoint Subscription Settings Service is running" -ForegroundColor Gray 
}



Write-Host
Write-Host "(6) Getting Application Pool for hosting service applications.." -ForegroundColor White
Write-Host "    .. getting service application..." -ForegroundColor Gray 
$appPoolServiceApps = Get-SPServiceApplicationPool -Identity "SharePoint Web Services Default"
Write-Host "    Obtained app pool" -ForegroundColor Gray 



Write-Host
Write-Host "(7) Creating Subscription Settings Service Application.." -ForegroundColor White
Write-Host "    .. creating Subscription Settings Service Application..." -ForegroundColor Gray 
$appSubSvc = New-SPSubscriptionSettingsServiceApplication –ApplicationPool $appPoolServiceApps –Name "Settings Service Application" –DatabaseName SettingsServiceDB 
Write-Host "    Subscription Settings Service Application created" -ForegroundColor Gray 
Write-Host "    .. creating Subscription Settings Service Application proxy..." -ForegroundColor Gray 
$proxySubSvc = New-SPSubscriptionSettingsServiceApplicationProxy –ServiceApplication $appSubSvc
Write-Host "    Subscription Settings Service Application proxy created" -ForegroundColor Gray 



Write-Host
Write-Host "(8) Creating App Management Service Application.." -ForegroundColor White
Write-Host "    .. creating App Management Service Application..." -ForegroundColor Gray 
$appAppSvc = New-SPAppManagementServiceApplication -ApplicationPool $appPoolServiceApps -Name "App Management Service Application" -DatabaseName AppServiceDB
Write-Host "    App Management Service Application created" -ForegroundColor Gray 
Write-Host "    .. creating App Management Service Application proxy..." -ForegroundColor Gray 
$proxyAppSvc = New-SPAppManagementServiceApplicationProxy -ServiceApplication $appAppSvc
Write-Host "    App Management Service Application proxy created" -ForegroundColor Gray 



Write-Host
Write-Host "(9) Setting Tenant URL Prefix for Deployed Apps .." -ForegroundColor White
Set-SPAppSiteSubscriptionName -Name "app" -Confirm:$false



Write-Host 
Write-Host "Finished configuring SharePoint 2013 to host apps! Script details are as follows:" -ForegroundColor Green
Write-Host

Write-Host "=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=" -ForegroundColor White
Write-Host "App Host Domain:  *.$appHostDomain" -ForegroundColor White
Write-Host "App URL Prefix:   app" -ForegroundColor White
Write-Host "=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=" -ForegroundColor White
Write-Host 
