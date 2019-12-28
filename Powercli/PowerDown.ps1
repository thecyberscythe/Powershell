# Data Center Emergency PowerDown Script
# January 1, 2020
# Shawn Stephens
# Suspends all VM's in each cluster
# Powers Blades down for each Cluster once all VM's are suspended
# Moves through Cluster_3-> Cluster 1 -> OOB


Write-Host "Begining the ShutDown Sequence!" -Background "black" -ForegroundColor "Yellow"
Write-Host "Follow any prompts on the console!" -Background "black" -ForegroundColor "Yellow"
Write-Host "This process will take about 10 Minutes to complete!" -Background "black" -ForegroundColor "Yellow"

###########################
### Shared Variables ###
###########################

$connection = Connect-VIServer -Server(Read-Host "Enter the Vsphere or ESXI Server Address") -Credential(Get-Credential) -Protocol Https -Force
$build = Read-Host "What is the Data Center Number you are powering Down? EX: 00/01"
$date = get-date 
$note = Set-VM -Notes "$($.Notes) Emergency Shutdown on $date"
$snapshot = New-Snapshot -name "Emergency Snapshot" -Description "Emergency Snapshot created on $date " -Confirm:$false -memory:$false -RunAsync 
$disconnect = Disconnect-VIServer -server * -Confirm:$false -Force
$s = 1




###########################
### Cluster VM Gathering Variables###
###########################
$oobvms = Get-VM -location "TSEC$build-OOB"
$Cluster_1vms = Get-VM -location "TSEC$build-Cluster_1"
$Cluster_3vms = Get-VM -location "TSEC$build-Cluster_3"

###########################
### Cluster Host Gathering Variables###
###########################

$oobhost = Get-VMhost -location "TSEC$build-OOB" 
$Cluster_1host = Get-VMhost -location "TSEC$build-Cluster_1"
$Cluster_3host = Get-VMhost -location "TSEC$build-Cluster_3"

$connection
###########################
### Cluster_3-Shutdown ###
###########################
function Cluster_3_Shutdown{
    $Cluster_3vms | $note | Where-Object {$_.powerstate -eq 'PoweredOn'} | Suspend-VM
    start-sleep -Seconds 120
    $Cluster_3host | Stop-VMHost -Confirm:$false -Force -RunAsync
}



###########################
### Cluster_1-Shutdown ###
###########################
function Cluster_1_Shutdown{
    $Cluster_1vms | $note | Where-Object {$_.powerstate -eq 'PoweredOn'} | Suspend-VM
    $Cluster_1vms | $snapshot
    start-sleep -Seconds 120
    $Cluster_1host | Stop-VMHost -Confirm:$false -Force -RunAsync
}


###########################
### OOB-Shutdown ###
###########################
function OOB_VM_Shutdown{
    $oobvms | $snapshot
    $oobvms | Where-Object { $_.Name -notlike '*idm*' -and $_.Name -notlike '*vcs*'} | Shutdown-VMGuest -Confirm:$false
    Get-VM -Name "TSEC$buildCluster_1idm*" -location "TSEC$build-OOB" | Shutdown-VMGuest -Confirm:$false
    Get-VM -Name "TSEC$buildCluster_1vcs*" -location "TSEC$build-OOB" | Shutdown-VMGuest -Confirm:$false
    start-sleep -Seconds 120
}
function OOB_Shutdown{
    Write-Host "Enter OOB Blade $s ESXI Host IP"
    $connection
    Stop-VMHost -Confirm:$false -Force -RunAsync
    $disconnect
    $S++
}

Cluster_3_Shutdown
Cluster_1_Shutdown
OOB_Shutdown
OOB_Shutdown
OOB_Shutdown





