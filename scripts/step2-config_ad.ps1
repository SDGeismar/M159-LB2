#requires ñrunasadministrator
# ------------------------------------------
# Step 2: Deploy AD
# Author: VK (c) 2017

#Cmdlet binding if user wants Silent installation
[CmdletBinding()]
Param(
        
    [Parameter(Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [switch]$Silent         
)
$FolderPath = $PSScriptRoot
#Start Logging
Start-Transcript -Path "$FolderPath\Setup.log" -Append

Write-Host "Will now install ADDS components"
Install-windowsfeature -name AD-Domain-Services -IncludeManagementTools  

Write-Host "Will now init and format all 3 disks accordingly."
Write-Host "Ensure all 3 disks are connected, otherwise add them first."

if(!$Silent){
    pause
}

New-Item C:\directory -ItemType Directory
New-Item C:\protocol -ItemType Directory

Write-Host "Will now change existing drive letter D:\ to E:\."
# Alter CD ROM drive letter
Get-WmiObject -Class Win32_volume -Filter "DriveLetter = 'D:'" |`    Set-WmiInstance -Arguments @{DriveLetter='E:'}

Write-Host "Will now set up all 3 disks."
# Set up all disks
# ja me ch√∂nnt das mitere for schleife mache abr ig bi zu faul

$Disk = Get-Disk 1
$Disk | Initialize-Disk -PartitionStyle MBR
$Disk | New-Partition -UseMaximumSize -MbrType IFS
$Partition = Get-Partition -DiskNumber $Disk.Number
$Partition | Format-Volume -FileSystem NTFS -Confirm:$false
$Partition | Add-PartitionAccessPath -AccessPath "C:\directory"

$Disk = Get-Disk 2
$Disk | Initialize-Disk -PartitionStyle MBR
$Disk | New-Partition -UseMaximumSize -MbrType IFS
$Partition = Get-Partition -DiskNumber $Disk.Number
$Partition | Format-Volume -FileSystem NTFS -Confirm:$false
$Partition | Add-PartitionAccessPath -AccessPath "C:\protocol"

$Disk = Get-Disk 3
$Disk | Initialize-Disk -PartitionStyle MBR
$Disk | New-Partition -AssignDriveLetter -UseMaximumSize -MbrType IFS
$Partition = Get-Partition -DiskNumber $Disk.Number
$Partition | Format-Volume -FileSystem NTFS `    -NewFileSystemLabel "Data" `    -Confirm:$false

Write-Host "Will now create sysvol dir on D:\"
New-Item D:\sysvol -ItemType Directory

Write-Warning "Alert! Domain setup will commence next!"
Write-Warning "Ensure DNS is working!"

if(!$silent)
{
    pause
}

if($Silent)
{
    #Setup Auto login
    Push-Location $folderPath
    . .\Set-AutoLogon.ps1
    Set-Autologon -Script "$FolderPath\step3-config_services.ps1 -Silent"
}


#
# AD DS Deployment Skreenkast
#

Import-Module ADDSDeployment
Install-ADDSForest `
-CreateDnsDelegation:$false `
-DatabasePath "C:\directory" `
-DomainMode "WinThreshold" `
-DomainName "ADS.M159.iet-gibb.ch" `
-DomainNetbiosName "ADS" `
-ForestMode "WinThreshold" `
-InstallDns:$true `
-LogPath "C:\protocol" `
-NoRebootOnCompletion:$false `
-SysvolPath "D:\sysvol" `
-Force:$true

Write-Host "Domain setup has concluded!"
#Stop logging
Stop-Transcript