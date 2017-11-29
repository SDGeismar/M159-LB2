
#requires –runasadministrator
# ---------------------------------------
# Step 1: Set up local machine for AD deplyoment
# (c) Valentin Klopfenstein & Geismar Silvio, 2017 - IET-GIBB

#Cmdlet binding if user wants Silent installation
[CmdletBinding()]
Param(
        
    [Parameter(Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [switch]$Silent         
)
$NetAdapter = Get-NetAdapter
$hostname = $env:COMPUTERNAME
$FolderPath = $PSScriptRoot

#Start Logging
Start-Transcript -Path "$FolderPath\Setup.log" -Append

$netname = Read-Host -Prompt 'Input your initials'
$octet = Read-Host -Prompt 'Input the last octet of your IP'
if($Silent){
    $LogonPassword = Read-Host -Prompt 'Input your password'
}

# Disable Windows Update
Set-Service -Name wuauserv -StartupType manual -Status Stopped

# Set Computer Name
Rename-Computer -NewName vmWS2$netname

# Manual timezone check
Write-Host "Check Timezone"
Get-TimeZone

# Set IP
Remove-NetIPAddress -InterfaceIndex $NetAdapter.InterfaceIndex -IPAddress *
New-NetIPAddress -InterfaceIndex $NetAdapter.InterfaceIndex `    -IPAddress 192.168.210.$octet `    -PrefixLength 24

# Disable all Firewall profiles
Get-NetFirewallProfile | Set-NetFirewallProfile -Enabled false 


# Disable UAC
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" `    -Name "EnableLUA" -Value 0
# Enable RDP Access to host
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" `    -Name "fDenyTSConnections" -Value 0

# Set logout timeout
powercfg -change -monitor-timeout-ac 0
powercfg -change -monitor-timeout-dc 0

# Disable password complexity
secedit /export /cfg c:\secpol.cfg
(Get-Content C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") `    | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY
rm -force c:\secpol.cfg -confirm:$false

# Disable enhanced IE security
# NOTE: Courtesy of https://stackoverflow.com/a/9368555
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" `    -Name "IsInstalled" -Value 0
Stop-Process -Name Explorer
if($Silent)
{
    #Setup Auto login
    Push-Location $folderPath
    . .\Set-AutoLogon.ps1
    Set-Autologon -DefaultUsername $env:USERNAME `        -DefaultPassword $LogonPassword `        -AutoLogonCount 2 `        -Script "$FolderPath\step2-config_ad.ps1 -Silent"
}
#Stop logging
Stop-Transcript

# End
Write-Warning "Alert! Next step will forcefully shut this system down in 10 seconds!"
if(!$silent)
{
    pause
}
Write-Host "After reboot please continue with step 2."
Write-Warning "Abort with 'shutdown /a'."
shutdown /f /r /t 10