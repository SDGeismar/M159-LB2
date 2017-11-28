# This file simply contains random PS commands.
# It serves no purpose whatsoever.

Get-ADObject -SearchBase (Get-ADRootDSE).ConfigurationNamingContext -filter "objectclass -eq 'site'" | Rename-ADObject -NewName Thun

Get-ADForest ADS.M159.iet-gibb.ch | FL GlobalCatalogs
