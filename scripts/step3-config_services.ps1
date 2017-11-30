#requires �runasadministrator
# ------------------------------------------------
# Post ADDS-deployment configuration
# This script configures DHCP, OUs, DNS and all that crap

#Cmdlet binding if user wants Silent installation
[CmdletBinding()]
Param(
        
    [Parameter(Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [switch]$Silent         
)
$FolderPath = $PSScriptRoot
#Start Logging
Start-Transcript -Path "$FolderPath\Setup.log" -Append

Import-Module ActiveDirectory 

$dc = $env:COMPUTERNAME
$ip = Test-Connection -ComputerName (hostname) -Count 1  | `
        Select -ExpandProperty IPV4Address
$binreg = "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\NonEnum"

# DHCP config
Write-Host " "
Write-Host "Now installing and authorizing DHCP Service"
Install-WindowsFeature DHCP -IncludeManagementTools
Add-DhcpServerInDC -DnsName ADS.M159.iet-gibb.ch -IPAddress $ip
Write-Host " "
Write-Host "Now setting Scope on CN=ADS"
Add-DhcpServerv4Scope -Name 'ADS DHCP' `
    -StartRange 192.168.210.1 `
    -EndRange 192.168.210.100 `
    -SubnetMask 255.255.255.0 `
    -Description 'ADS DHCP default scope' `
    -cn $dc
Write-Host " "

# OUs

Write-Host "Now setting up OUs"
import-csv $FolderPath\ou.csv -delimiter ";"| New-ADOrganizationalUnit -PassThru
Write-Host "Now setting up security groups"
New-ADGroup -Name "M" -SamAccountName M `
    -GroupCategory Security `
    -GroupScope Global `
    -DisplayName "Management" `
    -Path "OU=Management,OU=Company,DC=ADS,DC=M159,DC=iet-gibb,DC=ch" `
    -Description "Management"  
New-ADGroup -Name "E" `
    -SamAccountName E `
    -GroupCategory Security `
    -GroupScope Global `
    -DisplayName "EDV" `
    -Path "OU=EDV,OU=Company,DC=ADS,DC=M159,DC=iet-gibb,DC=ch" `
    -Description "EDV"  
New-ADGroup -Name "P" `
    -SamAccountName P `
    -GroupCategory Security `
    -GroupScope Global `
    -DisplayName "Production" `
    -Path "OU=Produktion,OU=Company,DC=ADS,DC=M159,DC=iet-gibb,DC=ch" `
    -Description "Production"  
Write-Host "Now setting up Users"
Import-Csv $folderpath\users.csv -delimiter ";" | `
    New-ADUser -PassThru | `
    Set-ADAccountPassword -Reset `
    -NewPassword (ConvertTo-SecureString -AsPlainText 'asdf1234' -Force) `
    -PassThru | Enable-ADAccount

echo "Now setting up OUs"
import-csv $psscriptroot\ou.csv -delimiter ";" | New-ADOrganizationalUnit -PassThru
echo "Now setting up Users"
import-csv $psscriptroot\users.csv -delimiter ";" | New-ADUser -PassThru | Set-ADAccountPassword -Reset -NewPassword (ConvertTo-SecureString -AsPlainText ‘asdf1234’ -Force) -PassThru | Enable-ADAccount

# DNS
Write-Host "Now setting up DNS"
Add-DnsServerResourceRecordA -Name "vmWP1" `
    -ZoneName "ADS.M159.iet-gibb.ch" `
    -AllowUpdateAny `
    -IPv4Address "192.168.210.10" `
    -TimeToLive 01:00:00

# GPOs
# Disable recycle bin on desktop
New-GPO -Name "Desktop_Remove" -comment "Omit recylce bin icon from desktop"
Set-GPRegistryValue -Name "Desktop_Remove" `
    -key $binreg `
    -ValueName "{645FF040-5081-101B-9F08-00AA002F954E}" `
    -Type String -value 1
New-GPLink -Name "Desktop_Remove" `
    -Target "OU=Company,DC=ADS,DC=M159,DC=iet-gibb,DC=ch"

# Disable password complexity
Set-ADDefaultDomainPasswordPolicy -ComplexityEnabled $false `
    -Identity ADS.M159.iet-gibb.ch

# Sites
# Rename current site to Bern
Get-ADObject -SearchBase (Get-ADRootDSE).ConfigurationNamingContext `
    -filter "objectclass -eq 'site'" | Rename-ADObject -NewName Bern

# Create new site and configure it
New-ADReplicationSite -Name Thun

# [!] UNTESTED [!]
New-ADReplicationSubnet -Name "192.168.210.0/25" -Site Bern
New-ADReplicationSubnet -Name "192.168.210.128/25" -Site Thun

# !!!!!!!!!!!!!!!!!!!!!!!!
# TODO: Create and assign Subnet to Site "Bern" and "Thun"
# !!!!!!!!!!!!!!!!!!!!!!!!


# !!!!!!!!!!!!!!!!!!!!!!!!
# TODO: Define replica schedule of DEFAULTIPSITELINK
# !!!!!!!!!!!!!!!!!!!!!!!!

# FSMO Management
# Register schmmgmt.dll
regsvr32 schmmgmt.dll

# [!] UNTESTED [!]
# Create and assign attribute to class "Person"
# Courtesy of https://blogs.technet.microsoft.com/heyscriptingguy/2015/06/17/powershell-and-the-active-directory-schema-part-2/
$schemaPath = (Get-ADRootDSE).schemaNamingContext
#$oid = New-AttributeID
$attributes = @{
      lDAPDisplayName = 'hobbies';
      attributeId = "2.16.756.5.32";
      oMSyntax = 20;
      attributeSyntax = "2.5.5.4";
      isSingleValued = $false;
      adminDescription = 'AB4 attribute';
      searchflags = 1
      }
New-ADObject -Name hobbies `
    -Type attributeSchema `
    -Path $schemapath `
    -OtherAttributes $attributes

# Assign Attribute to class
$userSchema = get-adobject -SearchBase $schemapath -Filter 'name -eq "person"'
$userSchema | Set-ADObject -Add @{mayContain = 'hobbies'} 
Stop-Transcript