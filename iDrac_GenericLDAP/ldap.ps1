# iDrac LDAP Configuration and Root Password Change Script for Dell M630, VRTX, M1000e, M640
# 10-25-2019
# Shawn Stephens
# Sets the LDAP Authentication for all Blades & Chassis in the csv files Selected.


start-sleep -s 1
$InitialDirectory = 'C:\'


Write-Host -BackgroundColor Black -ForegroundColor Yellow "Select A CSV File Containing the Hostname or IPs of the Blade Servers to be configured."
start-sleep -s 1

### Open CSV File to Use for Blade and Chassis Configuration ###

Function Get-FileName($InitialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

  $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
  $OpenFileDialog.initialDirectory = $initialDirectory
  $OpenFileDialog.filter = "CSV (*.csv) | *.csv"
  $OpenFileDialog.ShowDialog() | Out-Null
  $OpenFileDialog.FileName
}

### Open Root Cert File. PEM File ###
Function Get-Cert($InitialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

  $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
  $OpenFileDialog.initialDirectory = $initialDirectory
  $OpenFileDialog.filter = "PEM (*.pem) | *.pem"
  $OpenFileDialog.ShowDialog() | Out-Null
  $OpenFileDialog.FileName
}


###Creates a Log File and Imports the Server List That Will Be Looped Through###
###This does not capture user Input into the log file###
$csvlocation = Get-FileName
start-transcript -path 'C:\Logs\ldapconfigblades.txt'
$Servers = import-csv $csvlocation


###Starting Value of the Counter###
$S = 0

###Variable Block###
$user = Read-Host "Enter User"
$passwd = Read-Host "Enter Password"
Write-Host -BackgroundColor Black -ForegroundColor Yellow "User Name and Password Captured..."
$newpass = Read-Host "Enter the New Root Password..."

###Specific RACADM Settings###
$ldapserver = "idm01.tseclabs.com"
$ldapport = 636
$binddn = "uid=idrac.svc,cn=users,cn=accounts,dc=tseclabs,dc=com"
$bindpass = Read-Host "Enter the idrac.svc password Now!"
$baseDN = "cn=users,cn=accounts,dc=tseclabs,dc=com"
$uid = "uid"
$groupmember = "member"
$searchfilter = "memberOf=cn=iadmins,cn=groups,cn=accounts,dc=tseclabs,dc=com"
$certvalidation = 1
$enable = 1
$groupdn = "cn=iadmins,cn=groups,cn=accounts,dc=tseclabs,dc=com"
$priv = 511
$certspot = Get-Cert
$bitpriv = "0xfff"



###For Loop to Run RACADM Commands. Pulls Information from the CSV Above###
foreach($Server in $Servers)
{
    
    ############################ Common Settings ############################
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAP.CertValidationEnable $certvalidation
    Write-Host "Enabled CertValidation" -BackgroundColor Black -ForegroundColor Green
    racadm -r $Server.HostIP -u $user -p $passwd sslcertupload -t 2 -f $certspot
    Write-Host "Uploaded Cert" -BackgroundColor Black -ForegroundColor Green
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAP.Server $ldapserver
    Write-Host "Set the Ldap Server" -BackgroundColor Black -ForegroundColor Green
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAP.Port $ldapport
    Write-Host "Set the Port" -BackgroundColor Black -ForegroundColor Green
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAP.BindPassword $bindpass
    Write-Host "Set the Bind Password(idrac.svc)" -BackgroundColor Black -ForegroundColor Green
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAP.BindDN $binddn
    Write-Host "Set the Bind DN" -BackgroundColor Black -ForegroundColor Green
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAP.BaseDN $baseDN
    Write-Host "Set the Base DN" -BackgroundColor Black -ForegroundColor Green
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAP.UserAttribute $uid
    Write-Host "Set the User Attribute" -BackgroundColor Black -ForegroundColor Green
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAP.GroupAttribute $groupmember
    Write-Host "Set Group Member Attribute" -BackgroundColor Black -ForegroundColor Green
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAP.Searchfilter $searchfilter
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAP.Enable $enable
    Write-Host "Enabled LDAP" -BackgroundColor Black -ForegroundColor Green
    ############################ Group Settings ############################
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAPRoleGroup.1.DN $groupdn
    Write-Host "Set the Group DN" -BackgroundColor Black -ForegroundColor Green
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAPRoleGroup.1.Privilege $priv
    Write-Host "Set the Group Privilege" -BackgroundColor Black -ForegroundColor Green

     ############################ Root Password Change ############################
     racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.Users.2.Password $newpass
     Write-Host "Changed Root Password" -BackgroundColor Black -ForegroundColor Green

$S++
Write-Progress -Activity "###########Setting Up Blade LDAP Authentication###########" -status "Configured: $S of $($Servers.Count)" -PercentComplete (($S / $Servers.Count) * 100)
Write-Host -BackgroundColor Black -ForegroundColor Green "Configured LDAP Settings for " $Server.HostIP       
}

Write-Host -BackgroundColor Black -ForegroundColor Yellow "Select A CSV File Containing the Hostname or IPs of the Chassis Servers to be configured."
start-sleep -s 1
$chassiscsv = Get-FileName
start-transcript -path 'C:\Logs\ldapconfigchassis.txt'
$chassis = import-csv $chassiscsv
foreach($Server in $chassis)
{
    
    ############################ Common Settings ############################
    racadm -r $Server.HostIP -u $user -p $passwd  config -g cfgLDAP -o cfgLDAPCertValidationEnable  $certvalidation
    Write-Host "Enabled CertValidation" -BackgroundColor Black -ForegroundColor Green
    racadm -r $Server.HostIP -u $user -p $passwd  sslcertupload -t 2 -f $certspot
    Write-Host "Uploaded Cert" -BackgroundColor Black -ForegroundColor Green
    racadm -r $Server.HostIP -u $user -p $passwd  config -g cfgLDAP -o cfgLDAPServer $ldapserver
    Write-Host "Set the Ldap Server" -BackgroundColor Black -ForegroundColor Green
    racadm -r $Server.HostIP -u $user -p $passwd  config -g cfgLDAP -o cfgLDAPPort $ldapport
    Write-Host "Set the Port" -BackgroundColor Black -ForegroundColor Green
    racadm -r $Server.HostIP -u $user -p $passwd  config -g cfgLDAP -o cfgLDAPBindPassword $bindpass
    Write-Host "Set the Bind Password(idrac.svc)" -BackgroundColor Black -ForegroundColor Green
    racadm -r $Server.HostIP -u $user -p $passwd  config -g cfgLDAP -o cfgLDAPBindDN $binddn
    Write-Host "Set the Bind DN" -BackgroundColor Black -ForegroundColor Green
    racadm -r $Server.HostIP -u $user -p $passwd  config -g cfgLDAP -o cfgLDAPBaseDN $baseDN
    Write-Host "Set the Base DN" -BackgroundColor Black -ForegroundColor Green
    racadm -r $Server.HostIP -u $user -p $passwd  config -g cfgLDAP -o cfgLDAPUserAttribute $uid
    Write-Host "Set the User Attribute" -BackgroundColor Black -ForegroundColor Green
    racadm -r $Server.HostIP -u $user -p $passwd  config -g cfgLDAP -o cfgLDAPGroupAttribute $groupmember
    Write-Host "Set Group Member Attribute" -BackgroundColor Black -ForegroundColor Green
    racadm -r $Server.HostIP -u $user -p $passwd  config -g cfgLDAP -o cfgLDAPEnable $enable
    Write-Host "Enabled LDAP" -BackgroundColor Black -ForegroundColor Green
    ############################ Group Settings ############################
    #racadm -r $Server.HostIP -u $user -p $passwd -g cfgLDAPRoleGroup -o cfgLDAPRoleGroupIndex 1
    racadm -r $Server.HostIP -u $user -p $passwd config -g cfgLDAPRoleGroup -i 1 -o cfgLdapRoleGroupDN $groupdn
    Write-Host "Set Group DN" -BackgroundColor Black -ForegroundColor Green
    racadm -r $Server.HostIP -u $user -p $passwd config -g cfgLDAPRoleGroup -i 1 -o cfgLdapRoleGroupPrivilege $bitpriv
    Write-Host "Set Group Privilege" -BackgroundColor Black -ForegroundColor Green

    ############################ Root Password Change ############################
    Write-Host "Changing Root Password" -BackgroundColor Black -ForegroundColor Red
    racadm -r $Server.HostIP -u $user -p $passwd config -g cfgUserAdmin -i 1 -o cfgUserAdminPassword $newpass
    Write-Host "Changed Root Password" -BackgroundColor Black -ForegroundColor Green

$S++
Write-Progress -Activity "###########Setting Up Blade LDAP Authentication###########" -status "Configured: $S of $($Servers.Count)" -PercentComplete (($S / $Servers.Count) * 100)
Write-Host -BackgroundColor Black -ForegroundColor Green "Configured LDAP Settings for " $Server.HostIP       
}

Write-Host "!!!LDAP Settings Set for Servers and Chassis !!!" -ForegroundColor Green
Write-Host "### Check C:\Logs ### for the Log of this Script" -ForegroundColor Yellow


Stop-Transcript
