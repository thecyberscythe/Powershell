# ESXI_Password Change
# 10-20-2019
# Shawn Stephens
# Sets advanced settings for all the ESXI hosts

start-sleep -s 3

Function Get-FileName($InitialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

  $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
  $OpenFileDialog.initialDirectory = $initialDirectory
  $OpenFileDialog.filter = "CSV (*.csv) | *.csv"
  $OpenFileDialog.ShowDialog() | Out-Null
  $OpenFileDialog.FileName
}
$csvlocation = Get-FileName
start-transcript -path 'C:\Logs\advancedsettings.txt'
$Servers = import-csv $csvlocation


$S = 0
$passwd = Get-Credential -Message "Enter the current ESXI Credentials"

$ntp = Read-Host "Enter the NTP Server IP"
$iscsi = Read-Host "Enter the iscsi Target address. 192.25.1.128"
$syslog = Read-Host "Enter the syslog server address. Example tcp://192.25.99.151:514"

foreach($Server in $Servers)
{

    ###Connect to each ESXI Host###
    connect-viserver -server $Server.HostIP -Credential $passwd -protocol https -Force
    
    ###Variables###
    $esxcli = Get-EsxCli
    $esxcli
    Set-VMHostAdvancedConfiguration -Name "Mem.AllocGuestLargePage" -Value "0"
    Set-VMHostAdvancedConfiguration -Name "UserVars.SuppressCoredumpWarning" -Value "1"
    New-IscsiHbaTarget -IScsiHBA vmhba72 -Type Send -Address $iscsi
    Add-VMHostNtpServer -NtpServer $ntp
    Get-VmHostService | Where-Object {$_.key -eq "ntpd"} | Start-VMHostService
    Get-VmHostService | Where-Object {$_.key -eq "ntpd"} | Set-VMHostService -policy "on"
    Set-VMHostSysLogServer -SysLogServer $syslog
    Set-VMHostAdvancedConfiguration -Name "NFS41.MaxVolumes" -Value "10"
    
    
    Disconnect-viserver -Server * -Force -Confirm:$false
$S++
Write-Progress -Activity "###########Setting Advanced Options on the ESXI Hosts###########" -status "Configured: $S of $($Servers.Count)" -PercentComplete (($S / $Servers.Count) * 100)

}


Write-Host "!!!Large Page,Core Dump, Iscsi Dynamic Settings, Max NFS 4 mounts, Set Successfully!!!" -ForegroundColor Black -BackgroundColor Green

Stop-Transcript