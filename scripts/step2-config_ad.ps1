# ------------------------------------------
# Deploy AD
# Author: VK (c) 2017

echo "Will now install ADDS components"
Install-windowsfeature -name AD-Domain-Services -IncludeManagementTools  

echo "Will now init and format all 3 disks accordingly."
echo "Ensure all 3 disks are connected, otherwise add them first."

pause

mkdir C:\directory
mkdir C:\protocol

echo "Will now change existing drive letter D:\ to E:\."
# Alter CD ROM drive letter
Get-WmiObject -Class Win32_volume -Filter "DriveLetter = 'D:'" |Set-WmiInstance -Arguments @{DriveLetter='E:'}

echo "Will now set up all 3 disks."
# Set up all disks
# ja me chönnt das mitere for schleife mache abr ig bi zu faul
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
$Partition | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Data" -Confirm:$false

echo "Will now create sysvol dir on D:\"
mkdir D:\sysvol

echo "Alert! Domain setup will commence next!"
echo "Ensure DNS is working!"

pause

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

echo "Domain setup has concluded!"
