# ---------------------------------------
# Powescript script

$NetAdapter = Get-NetAdapter
$hostname = hostname

# Disable Windows Update
Set-Service -Name wuauserv -StartupType manual -Status Stopped
# Set Computer Name
Rename-Computer -NewName vmWS2-vk
# Manual timezone check
Write-Host "Check Timezone"
Get-TimeZone
# Set IP - To be fixed
# Currently sets netmask with 32 bits (255.255.255.255)
Remove-NetIPAddress -InterfaceIndex $NetAdapter.InterfaceIndex -IPAddress *
New-NetIPAddress -InterfaceIndex $NetAdapter.InterfaceIndex -IPAddress 192.168.210.104
# Disable all Firewall profiles
Get-NetFirewallProfile | Set-NetFirewallProfile -Enabled false
# Disable UAC
Set-ItemProperty -Path “HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System” -Name “EnableLUA” -Value 0
# Enable RDP Access to host
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" –Value 0
# Set logout timeout
powercfg -change -monitor-timeout-ac 0
powercfg -change -monitor-timeout-dc 0
# Disable password complexity
secedit /export /cfg c:\secpol.cfg
(gc C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY
rm -force c:\secpol.cfg -confirm:$false
# Disable enhanced IE security
# NOTE: Courtesy of https://stackoverflow.com/a/9368555
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0
Stop-Process -Name Explorer

# end
echo "Alert! Next step will forcefully shut down this system in 20 seconds!"
pause
echo "After reboot please continue with step 2."
echo "Abort with 'shutdown /a'."
shutdown /f /r /t 20
