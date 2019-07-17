param (
    [alias('d')]   [switch] $debug,
    [alias('swu')] [siwtch] $skipWindowsUpdate
);

Set-Location $PSScriptRoot
. .\scripts\functions.ps1

EnsureAdmin

Write-Host "Set up  basic software"

EnsureChocoPackage pswindowsupdate


EnsureChocoPackage puppet-agent


if(-Not($skipWindowsUpdate)){
  #update windows
  choco upgrade pswindowsupdate -y
  Get-WUInstall
}

#install puppet agent
choco upgrade puppet-agent -y

$argsJoined = $args -join ' '
. ./setup_site_pp_only.ps1 $argsJoined

#WaitForAnyKey
