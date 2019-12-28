# Random PowerCLI Automation
# 12-16-2019
# Shawn Stephens


###########################################
### General Commands###
########################################### 
connect-viserver -server 10.100.43.210 -Credential(Get-Credential) -protocol https -Force

$datastore = Read-Host "Enter the Datastore that you are working with..>"


###########################################
### Remove ISOs/CD Drive from VMs###
########################################### 
Get-vm -Datastore Vendor1_Cluster3_ds_01 | Set-CDDrive -CD -IsoPath -Connected $false
$Cluster3host = Get-VMHost -Location "TSEC01-Cluster3" | Remove-Datastore -Datastore "Vendor1_Cluster3_ds_01" -VMhost $Cluster3host
Remove-Datastore -Datastore "Vendor1_Cluster3_ds_01" -VMhost $Cluster3host
Set-CDDrive -NoMedia 


###########################################
#### Remove Network Adapters not assigned to a wire.###
########################################### 

get-vm -Datastore Cluster3_ds_vol01 | Get-NetworkAdapter -Name "Network adapter 1" | Remove-NetworkAdapter

###########################################
### Unmount Datastore from Hosts###
########################################### 
$hosts = Get-VMHost -Location(Read-Host "Enter Cluster. All Hosts will be gathered") | Remove-Datastore -Datastore(Read-host "Enter the Datastore Name to be removed...") -WhatIf
get-vmhost -Location "TSEC01-Cluster3" | Remove-Datastore -Datastore Cluster3_ds_vol01
get-vm -location "TSEC01-Cluster3" | Where-Object {$_.powerstate -eq 'PoweredOn'} 
New-Datastore 

###########################################
### Manage Powerstate of VMs###
########################################### 
get-vm -Datastore Cluster3_ds_vol01 | Where-Object {$_.powerstate -eq 'PoweredOn'} | Suspend-VM
get-vm -Datastore Cluster3_ha_ds_01 | Where-Object {$_.powerstate -eq 'Suspended'} | Start-VM

###########################################
### Move VMs between Datastores###
########################################### 
get-vm -Datastore Cluster3_ds_vol01  |  Where-Object {$_.powerstate -eq 'PoweredOff'} | Move-VM -Datastore Cluster3_ha_ds_01 -RunAsync
get-vm -Datastore Cluster3_ds_vol01  |  Where-Object {$_.powerstate -eq 'Suspended'} | Move-VM -Datastore Cluster3_ha_ds_01 -RunAsync
get-vm -Datastore Cluster3_ds_vol01  |  Where-Object {$_.powerstate -eq 'PoweredOn'} | Move-VM -Datastore Cluster3_ha_ds_01 -RunAsync


###########################################
### Gather VMs and sets all networking to unconnected###
########################################### 
get-vm -Datastore Cluster3_ds_vol01 | Get-NetworkAdapter |Set-NetworkAdapter -Connected:$false

###########################################
### Get Task and Request the task stop###
########################################### 

get-task | Stop-Task -confirm:$false
Get-Task -status running    

###########################################
###  Maintenance Mode One Liners###
########################################### 
Get-vmhost -Name "Blade01.tseclabs.com" | Set-vmhost -state Maintenance -confirm:$false -Evacuate
Get-VMHost -Location "TSEC01-Cluster3" | Set-VMhost -State Maintenance -Confirm:$false -RunAsync
Get-VMHost -Location "TSEC01-Cluster3" | Remove-Datastore -Datastore "Cluster3_ds_vol01" -WhatIf 

Set-Datastore -datastore Cluster3_ds_vol01 -MaintenanceMode $true

###########################################
###  Restart all hosts in Cluster3###
########################################### 

Get-VMHost -Location "TSEC01-Cluster3" | Restart-vmhost -Confirm:$false -RunAsync
Restart-vmhost
###########################################
### Measure the Number of VMs with name Dev###
########################################### 
get-vm | where-object {$_.Name -like 'Dev_*'}| Measure-Object



###########################################
### Consolidate VM Snapshots/Generate Consolidation Cluster3###
########################################### 

Get-VM -Datastore Cluster3_ds_vol01 | where-Object {$_.Extensiondata.Runtime.ConsolidationNeeded} | ForEach-Object {$_.ExtensionData.ConsolidateVMDisks()}
Get-VM | Where-Object {$_.Extensiondata.Runtime.ConsolidationNeeded} | export-csv -path "consolidatelist.csv"

$counter = 0
Get-VM -Datastore Cluster3_ds_vol01 | where-Object {$_.Extensiondata.Runtime.ConsolidationNeeded} | ForEach-Object {$_.ExtensionData.ConsolidateVMDisks()
	 $counter++
	 Write-progress -Activity 'Consolidating VMs' -PercentComplete (($counter / $_.count) * 100)
	 }

###########################################
### Delete Old Clones then Clone OOB VMS to NFS Share###
########################################### 
$Deletebackups = Get-vm -Datastore "OOB_Backups" | where-object {$_.Name -ccontains "_Clone"} | Remove-VM -DeletCluster3ermanently:$True Confirm:$false -RunAsync
$srcvms = get-vm -Datastore "local_storage" | select-object -expandproperty Name

Foreach ($srcvm in $srcvms) {

	$srvcvms_strip = $srcvm

	new-vm -name "$srvcvms_strip`_Clone" -vm $srcvm -Datastore "OOB_Backups" -ResourcCluster3ool "TSEC01-OOB" -DiskStorageFormat "thin" -RunAsync

    Get-vm -Datastore "OOB_Backups"

}


Disconnect-viserver -Server * -Force -Confirm:$false

###########################################
### Delete Old Clones then Clone OOB VMS to NFS Share###
########################################### 
get-task | export-csv
Import-Csv

###########################################
### Get tasks and import csv to stop specific tasks
### Requires copying out the specific tasks to a new csv
########################################### 
$tasks = import-csv -path "C:\Users\shawn.stephens\Desktop\powershell\vmware\Scripts\tasks.csv" |
Select-Object -ExpandProperty Id

foreach ($task in $tasks)
{
    Get-task -id $task  | stop-task -Confirm:$false
}


###########################################
### Migrate VM for specific time - Working On###
########################################### 
$TimeStart = Get-Date
$TimeEnd = $timeStart.addminutes(.1)
Write-Host "Start Time: $TimeStart"
write-host "End Time:   $TimeEnd"
Do { 
 $TimeNow = Get-Date
  if ($TimeNow -ge $TimeEnd) {
  Write-host "It's time to finish."
 } else {
  Write-Host "Not done yet, it's only $TimeNow"
 }
 Start-SleCluster3 -Seconds 10
}
Until ($TimeNow -ge $TimeEnd)



$count = Get-task -status Running | Measure-Object
while ($count -le 3){
	get-vm -Datastore Cluster3_ha_ds_01  |  Where-Object {$_.powerstate -eq 'PoweredOff'} | Move-VM -Datastore Cluster3_ds_vol01 -RunAsync
} 
