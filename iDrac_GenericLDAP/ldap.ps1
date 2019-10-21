# ESXI_Password Change
# 10-16-2019
# Shawn Stephens
# Sets the LDAP Authentication for all servers in the csv file.

start-sleep -s 3

start-transcript -path 'C:\Users\shawnstephens\Desktop\Code Bank\Drac Config\Logs\ldapconfig.txt'
$Servers = import-csv 'C:\Users\shawnstephens\Desktop\Code Bank\Drac Config\hosts.csv'

$S = 0

###Variable Block###
$user = Read-Host "Enter User"
$passwd = Read-Host "Enter Password"
$ldapserver = "testldap01.tseclabs.com"
$ldapport = 636
$binddn = "uid=idrac.svc,cn=users,cn=accounts,dc=tseclabs,dc=com"
$bindpass = Read-Host "Enter the idrac.svc password Now!"
$baseDN = "cn=users,cn=accounts,dc=tseclabs,dc=com"
$uid = "uid"
$groupmember = "member"
$searchfilter = "memberOf=cn=infrastructure_admins,cn=groups,cn=accounts,dc=tseclabs,dc=com"
$certvalidation = 1
$enable = 1
$groupdn = "cn=infrastructure_admins,cn=groups,cn=accounts,dc=tseclabs,dc=com"
$priv = 511
$certspot = "C:\Users\shawn.stephens\Desktop\Code Bank\Drac Config\rootcagoshere.pem"

foreach($Server in $Servers)
{
    
    ############################ Common Settings ############################
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAP.CertValidationEnable $certvalidation
    racadm -r $Server.HostIP -u $user -p $passwd sslcertupload -t 2 -f $certspot
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAP.Server $ldapserver
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAP.Port $ldapport
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAP.BindPassword $bindpass
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAP.BindDN $binddn
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAP.BaseDN $baseDN
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAP.UserAttribute $uid
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAP.GroupAttribute $groupmember
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAP.Searchfilter $searchfilter
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAP.Enable $enable
    ############################ Group Settings ############################
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAPRoleGroup.1.DN $groupdn
    racadm -r $Server.HostIP -u $user -p $passwd set iDRAC.LDAPRoleGroup.1.Privilege $priv
    
    

$S++
Write-Progress -Activity "###########Setting Advanced Options on the ESXI Hosts###########" -status "Configured: $S of $($Servers.Count)" -PercentComplete (($S / $Servers.Count) * 100)
Write-Host -BackgroundColor Black -ForegroundColor Green "Configured LDAP Settings for " $Server.HostIP       
}

Write-Host "!!!LDAP Settings Set for Servers !!!" -ForegroundColor Black -BackgroundColor Green

Stop-Transcript