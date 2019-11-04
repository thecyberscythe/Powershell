# ESXI_Password Change
# 7-17-2019
# Shawn Stephens
# Change the Root Password for all the ESXI hosts

start-sleep -s 1
Function Get-FileName($InitialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

  $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
  $OpenFileDialog.initialDirectory = $initialDirectory
  $OpenFileDialog.filter = "CSV (*.csv) | *.csv"
  $OpenFileDialog.ShowDialog() | Out-Null
  $OpenFileDialog.FileName
}


    ##############################
    #Import CSV and Start Log#
    ##############################

$csvlocation = Get-FileName
start-transcript -path 'C:\Logs\passwordroll.txt'
$Servers = import-csv $csvlocation

$passwd = Get-Credential -Message "Enter the current ESXI Credentials"
$newpasswd = Read-Host "Enter the New Root Password!!"

$S = 0

foreach($Server in $Servers)
{

    ##############################
    #Connect to the ESXI Host#
    ##############################

    connect-viserver -server $Server.HostIP -Credential $passwd -protocol https -Force
    
    ##############################
    #Roll the Password#
    ##############################
    Get-EsxCli
    Get-VMHost
    Set-VMHostAccount -UserAccount root -Password $newpasswd
    

    Disconnect-viserver -Server * -Force -Confirm:$false
$S++
Write-Progress -Activity "Changing Passwords" -status "Configured: $S of $($Servers.Count)" -PercentComplete (($S / $Servers.Count) * 100)

}

Write-Host "!!!Root Password Change Complete!!!" -ForegroundColor Black -BackgroundColor Green

Stop-Transcript