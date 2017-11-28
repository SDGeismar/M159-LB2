# This file just contains some PS commands.
# other than that, it serves no purpose.

Get-ADObject -SearchBase (Get-ADRootDSE).ConfigurationNamingContext -filter "objectclass -eq 'site'" | Rename-ADObject -NewName Thun

Get-ADForest ADS.M159.iet-gibb.ch | FL GlobalCatalogs
