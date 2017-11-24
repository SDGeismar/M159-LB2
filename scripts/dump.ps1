# This file just contains some PS commands.
# The script itself serves no purpse

Get-ADObject -SearchBase (Get-ADRootDSE).ConfigurationNamingContext -filter "objectclass -eq 'site'" | Rename-ADObject -NewName Thun
