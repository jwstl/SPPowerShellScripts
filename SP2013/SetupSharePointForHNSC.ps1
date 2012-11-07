# =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
#       Script: SetupSharePointForHNSC.ps1
#
#       Author: Critical Path Training, LLC
#               http://www.CriticalPathTraining.com
#
#  Description: Configures a SharePoint 2013 install for hosting Host-Named Site Collections (HNSC).
#               This involves creating a Web Application in SharePoint that has no host header bindings.
#               Using DNS, all requests are mapped to this Web Application. You then create the site collections
#                   via PowerShell as you can't create HNSC's via the browser (Central Administration).
#
# Optional Parameters:
#               $WebApplicationName - Name of the Web application to create to host HNSC's.
#                 DEFAULT - "SharePoint HNSC Host - 80"
#               $AppPoolName - Name of the app pool to create to host the HNSC Web Application.
#                 DEFAULT - "SharePoint Default HNSC AppPool"
#               $ManagedAccountUsername - Username of the managed account to create for the app pool's identity.
#                 DEFAULT - WINGTIP\SP_Content
#               $WfeName - SharePoint WFE name.
#                 DEFAULT - WINGTIPALLUP
#               $DeleteCACreatedWebApp - Flag indicating if the default Web Application ceated by CA 
#                 should be deleted.
#                 DEFAULT - TRUE
#               $CreateDefaultSiteCollections - Flag indicating if two default site collections should be created.
#                 These are intranet.wingtip.com (team site) & dev.wingtip.com (developer site).
#                 DEFAULT - TRUE
# =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=

param(
	[string]$WebApplicationName = "SharePoint HNSC Host - 80",
	[string]$AppPoolName = "SharePoint Default HNSC AppPool",
	[string]$ManagedAccountUsername = "WINGTIP\SP_Content",
	[string]$WfeName = "WINGTIPALLUP",
	[switch]$DeleteCACreatedWebApp = $true,
	[switch]$CreateDefaultSiteCollections = $true
)
$ErrorActionPreference = 'Stop'

$appHostDomain = "apps.wingtip.com"

Write-Host
Write-Host "Configuring SharePoint Server 2013 Hosting Named Site Collection" -ForegroundColor White
Write-Host " Script Steps:" -ForegroundColor White
Write-Host " (0) Validating parameters..." -ForegroundColor White
Write-Host " (1) Verify SharePoint PowerShell Snapin Loaded" -ForegroundColor White
Write-Host " (2) Deleting default Central Administration Created Web Application" -ForegroundColor White
Write-Host " (3) Verifing / Creating New App Pool Managed Account" -ForegroundColor White
Write-Host " (4) Creating New Web Application to Service HNSC's" -ForegroundColor White
Write-Host " (5) Creating Default Site Collections" -ForegroundColor White
Write-Host

#
# verify parameters passed in
#
Write-Host "(0) Validating parameters..." -ForegroundColor White
if ($WebApplicationName -eq $null -xor $WebApplicationName -eq ""){
	Write-Error '$WebApplicationName is required'
	Exit
}
if ($AppPoolName -eq $null -xor $AppPoolName -eq ""){
	Write-Error '$AppPoolName is required'
	Exit
}
if ($ManagedAccountUsername -eq $null -xor $ManagedAccountUsername -eq ""){
	Write-Error '$ManagedAccountUsername is required'
	Exit
}
if ($WfeName -eq $null -xor $WfeName -eq ""){
	Write-Error '$WfeName is required'
	Exit
}



# Load SharePoint PowerShell snapin
Write-Host
Write-Host "(1) Verify SharePoint PowerShell Snapin Loaded..." -ForegroundColor White
$snapin = Get-PSSnapin | Where-Object {$_.Name -eq 'Microsoft.SharePoint.PowerShell'}
if ($snapin -eq $null) {
	Write-Host "    ..  Loading SharePoint PowerShell Snapin" -ForegroundColor Gray
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}
Write-Host "    Microsoft SharePoint PowerShell snapin loaded" -ForegroundColor Gray 



Write-Host
Write-Host "(2) Deleting default Central Administration Created Web Application..." -ForegroundColor White
if ($DeleteCACreatedWebApp -eq $true){
  Write-Host "    .. searching for default Web App, created by Central Administration..." -ForegroundColor Gray 
  $defaultWebApp = Get-SPWebApplication | Where-Object {$_.DisplayName -eq $WebApplicationName}
  if ($defaultWebApp -eq $null) {
    Write-Host "    .. failed to find default Web App" -ForegroundColor Yellow
    Write-Host "    Skipping this step" -ForegroundColor Yellow
    Write-Host "    ACTION: you should check Central Administration to see if a default Web App is present; having two default Web Apps is going to cause problems" -ForegroundColor Yellow
  } else {  
    Write-Host "    Found default web app, name = " $defaultWebApp.DisplayName -ForegroundColor Gray 
    Write-Host "    .. deleting default Web App..." -ForegroundColor Gray 
    Remove-SPWebApplication -Identity $defaultWebApp -DeleteIISSite -RemoveContentDatabases -Confirm:$false
    Write-Host "    Default Web App deleted" -ForegroundColor Gray 
  }
} else {
  Write-Host "    Skipping this step per parameter passed in" -ForegroundColor Gray 
}



Write-Host
Write-Host "(3) Verifing / Creating New App Pool Managed Account..." -ForegroundColor White
Write-Host "    .. Checking for existing managed account for user $ManagedAccountUsername..." -ForegroundColor Gray 
$managedAccount = Get-SPManagedAccount -Identity $ManagedAccountUsername
if ($managedAccount -ne $null) {
  Write-Host "    Found existing managed account for $ManagedAccountUsername, skipping this step" -ForegroundColor Gray 
} else {
  Write-Host "    .. creating new managed account for $ManagedAccountUsername..." -ForegroundColor Gray 
  Write-Host "    .. obtaining reference to WINGTIP\SP_Content account that will be a managed account for apps and Web Applications..." -ForegroundColor Gray 
  $securePassword = ConvertTo-SecureString "Password1" -AsPlainText -Force
  $contentAccountCredentials = New-Object System.Management.Automation.PSCredential("WINGTIP\SP_Content", $securePassword)
  Write-Host "    .. creating managed account for WINGTIP\SP_Content..." -ForegroundColor Gray 
  $managedAccount = New-SPManagedAccount $managedAccountCredentials
  Write-Host "    WINGTIP\SP_Content is now a managed account in SharePoint" -ForegroundColor Gray 
}



Write-Host
Write-Host "(4) Creating New Web Application to Service HNSC's..." -ForegroundColor White
Write-Host "    .. obtaining Active Directory claims authentication provider..." -ForegroundColor Gray 
$authProvider = New-SPAuthenticationProvider
Write-Host "    .. creating a new web application..." -ForegroundColor Gray 
$hnscWebApp = New-SPWebApplication -Name $WebApplicationName -AuthenticationProvider $authProvider -ApplicationPool $AppPoolName -ApplicationPoolAccount $managedAccount -DatabaseName "WSS_Content_HNSCDefaultHost"
Write-Host "    New HNSC Web Application created" -ForegroundColor Gray 
Write-Host "    .. creating default site collection at root without a template..." -ForegroundColor Gray 
$rootSite = New-SPSite -Name "Root HNSC Site Collection" -Url "http://wingtip.com" -HostHeaderWebApplication $hnscWebApp -OwnerAlias "WINGTIP\Administrator"
Write-Host "    Root site created" -ForegroundColor Gray 




Write-Host
Write-Host "(5) Creating Default Site Collections..." -ForegroundColor White
if ($CreateDefaultSiteCollections -eq $false) {
  Write-Host "    .. per parameter passed in, skipping this step" -ForegroundColor Gray 
} else {
  # create default team site
  Write-Host "    .. creating default team site..." -ForegroundColor Gray 
  $teamSite = New-SPSite -Name "Wingtip Intranet" -Url "http://intranet.wingtip.com" -HostHeaderWebApplication $hnscWebApp -Template "STS#0" -OwnerAlias "WINGTIP\Administrator"
  Write-Host "    Default team site created" -ForegroundColor Gray 
  
  # create default developer site
  Write-Host "    .. creating developer site..." -ForegroundColor Gray 
  $developerSite = New-SPSite -Name "Wingtip Developer Site" -Url "http://dev.wingtip.com" -HostHeaderWebApplication $hnscWebApp -Template "DEV#0" -OwnerAlias "WINGTIP\Administrator"
  Write-Host "    Developer site created" -ForegroundColor Gray 
}

Write-Host 
Write-Host "Finished configuring SharePoint Server 2013 for HNSC! Script details are as follows:" -ForegroundColor Green
Write-Host

Write-Host "=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=" -ForegroundColor White
Write-Host "Root Site Collection Details" -ForegroundColor White
Write-Host "Site URL:        " $rootSite.Url -ForegroundColor White
if ($CreateDefaultSiteCollections -eq $true) {
  Write-Host
  Write-Host "Default Team Site Collection Details" -ForegroundColor White
  Write-Host "Site Title:    " $teamSite.RootWeb.Title -ForegroundColor White
  Write-Host "Site URL:      " $teamSite.Url -ForegroundColor White
  Write-Host
  Write-Host "Developer Site Collection Details" -ForegroundColor White
  Write-Host "Site Title:    " $developerSite.RootWeb.Title -ForegroundColor White
  Write-Host "Site URL:      " $developerSite.Url -ForegroundColor White
}
Write-Host "=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=" -ForegroundColor White
Write-Host 