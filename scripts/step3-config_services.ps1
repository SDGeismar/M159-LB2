# ------------------------------------------------
# Post ADDS-deployment configuration
# This script configures DHCP, OUs, DNS and all that crap

Import-Module ActiveDirectory 

$dc = hostname
$ip = Test-Connection -ComputerName (hostname) -Count 1  | Select -ExpandProperty IPV4Address
$binreg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\NonEnum"

# DHCP config
echo " "
echo "Now installing and authorizing DHCP Service"
Install-WindowsFeature DHCP -IncludeManagementTools
Add-DhcpServerInDC -DnsName ADS.M159.iet-gibb.ch -IPAddress $ip
echo " "
echo "Now setting Scope on CN=ADS"
Add-DhcpServerv4Scope -Name 'ADS DHCP' -StartRange 192.168.210.1 -EndRange 192.168.210.100 -SubnetMask 255.255.255.0 -Description 'ADS DHCP default scope' –cn $dc
echo " "

# OUs
echo "Now setting up OUs"
import-csv ou.csv -delimiter ";"| New-ADOrganizationalUnit –PassThru
echo "Now setting up Users"
Import-Csv users.csv -delimiter ";" | New-ADUser -PassThru | Set-ADAccountPassword -Reset -NewPassword (ConvertTo-SecureString -AsPlainText ‘asdf1234’ -Force) -PassThru | Enable-ADAccount

# DNS
echo "Now setting up DNS"
Add-DnsServerResourceRecordA -Name "vmWp1" -ZoneName "ADS.local" -AllowUpdateAny -IPv4Address "192.168.210.10" -TimeToLive 01:00:00

# GPOs
# Disable recycle bin on desktop
New-GPO -Name "Desktop_Remove" -comment "Omit recylce bin icon on desktop"
Set-GPRegistryValue -Name "Desktop_Remove" -key $binreg -ValueName {645FF040-5081-101B-9F08-00AA002F954E} -Type String -value 1
New-GPLink -Name "Desktop_Remove" -Target OU=Company,DC=ADS,DC=M159,DC=iet-gibb,DC=dc

gpupdate /force
