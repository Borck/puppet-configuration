$argsJoined = $args -join ' '
$argsJoined += ' -install Minimal'

Invoke-Expression "& `"$PSScriptRoot\setup.ps1`" $argsJoined"
