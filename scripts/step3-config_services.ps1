# Post ADDS-deployment configuration
# This script configures DHCP, OUs, DNS and all that crap

$cn = hostname
$ip = Test-Connection -ComputerName (hostname) -Count 1  | Select -ExpandProperty IPV4Address

# DHCP config
echo " "
echo "Now installing and authorizing DHCP Service"
Install-WindowsFeature DHCP -IncludeManagementTools
Add-DhcpServerInDC -DnsName ADS.M159.iet-gibb.ch -IPAddress $ip
echo " "
echo "Now setting Scope on CN=ADS"
Add-DhcpServerv4Scope -Name 'ADS DHCP' -StartRange 192.168.210.1 -EndRange 192.168.210.100 -SubnetMask 255.255.255.0 -Description 'ADS DHCP default scope' –cn $cn
echo " "

# OUs
echo "Now setting up OUs"
New-ADOrganizationalUnit -Name "Management"
New-ADOrganizationalUnit -Name "EDV"
New-ADOrganizationalUnit -Name "Produktion"
