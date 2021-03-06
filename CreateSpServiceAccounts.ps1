# =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
#       Script: CreateSpServiceAccounts.ps1
#
#       Author: Critical Path Training, LLC
#               http://www.CriticalPathTraining.com
#
#  Description: Creates the necessary service accounts for SharePoint Server 2013.
#
#  Optional Parameters:
#               $AdDomain - AD domain where the users should be created.
#                          Default = DC=wingtip,DC=com
#               $AdUpnSuffix - AD UPN suffix
#                          Default = @wingtip.com
#               $Password - Password to assign to all accounts
#                          Default = Password1
# =+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=
param(
	[string]$AdDomain = "DC=cardinals,DC=com",
	[string]$AdUpnSuffix = "@cardinals.com",
	[string]$Password = "GamiGami1871!"
)

$ErrorActionPreference = 'Stop'

Write-Host 
Write-Host "Creating SharePoint service accounts!" -ForegroundColor Green
Write-Host " Script Steps:" -ForegroundColor White
Write-Host " (0) Validating parameters..." -ForegroundColor White
Write-Host " (1) Importing Active Directory Windows PowerShell Module..." -ForegroundColor White
Write-Host " (2) Creating farm account SP_Farm..." -ForegroundColor White
Write-Host " (3) Creating farm account SP_Content..." -ForegroundColor White
Write-Host " (4) Creating farm account SP_Services..." -ForegroundColor White
Write-Host " (5) Creating farm account SP_PortalAppPool..." -ForegroundColor White
Write-Host " (6) Creating farm account SP_ProfilesAppPool..." -ForegroundColor White
Write-Host " (7) Creating farm account SP_SearchService..." -ForegroundColor White
Write-Host " (8) Creating farm account SP_CacheSuperUser..." -ForegroundColor White
Write-Host " (9) Creating farm account SP_CacheSuperReader..." -ForegroundColor White
Write-Host

# create reference to AD OU "Users" and secure password string 
$AdOuUsers = "CN=Users,"+$AdDomain
$UserPassword = ConvertTo-SecureString -AsPlainText $Password -Force

#
# verify parameters passed in
#
Write-Host "(0) Validating parameters..." -ForegroundColor White
# AD domain
if ($AdDomain -eq $null -xor $AdDomain -eq ""){
	Write-Error '$AdDomain is required'
	Exit
}
# password
if ($Password -eq $null -xor $Password -eq ""){
	Write-Error '$Password is required'
	Exit
}

# import AD module
Write-Host "(1) Importing Active Directory Windows PowerShell Module..." -ForegroundColor White
Import-Module ActiveDirectory
Write-Host "    .. module loaded" -ForegroundColor Gray 

function CreateNewAdUser([string]$username)
{
  $userPrincipalName = $username + $AdUpnSuffix
  $newUser = New-ADUser -Path $AdOuUsers -SamAccountName $username -Name $username -DisplayName $username -EmailAddress $userPrincipalName -UserPrincipalName $userPrincipalName -Enabled $true -ChangePasswordAtLogon $false -PassThru -PasswordNeverExpires $true -AccountPassword $UserPassword
  Write-Host "    Created user $username" -ForegroundColor Gray 
}

# create users
Write-Host "(2) Creating farm account SP_Farm" -ForegroundColor White
CreateNewAdUser "SP_Farm"
Write-Host "(3) Creating farm account SP_Content" -ForegroundColor White
CreateNewAdUser "SP_Content"
Write-Host "(4) Creating farm account SP_Services" -ForegroundColor White
CreateNewAdUser "SP_Services"
Write-Host "(5) Creating farm account SP_PortalAppPool" -ForegroundColor White
CreateNewAdUser "SP_PortalAppPool"
Write-Host "(6) Creating farm account SP_ProfilesAppPool" -ForegroundColor White
CreateNewAdUser "SP_ProfilesAppPool"
Write-Host "(7) Creating farm account SP_SearchService" -ForegroundColor White
CreateNewAdUser "SP_SearchService"
Write-Host "(8) Create farm account SP_CacheSuperUser" -ForegroundColor White
CreateNewAdUser "SP_CacheSuperUser"
Write-Host "(9) Creating farm account SP_CacheSuperReader" -ForegroundColor White
CreateNewAdUser "SP_CacheSuperReader"

Write-Host 
Write-Host "Finished creating SharePoint service accounts!" -ForegroundColor Green
Write-Host