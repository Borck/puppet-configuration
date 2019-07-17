# param (
#     [switch]$d,
#     [switch]$debug
# );

Set-Location $PSScriptRoot
. .\scripts\functions.ps1

$ppModulePath = "$($PSScriptRoot)\environments\production\modules"

function puppetUpgradeModule($moduleName){
   puppet module upgrade $moduleName --force --modulepath $ppModulePath   
}


#EnsureAdmin
#EnsureChocoPackage puppet-agent


puppetUpgradeModule puppetlabs-chocolatey
puppetUpgradeModule puppetlabs-powershell
puppetUpgradeModule puppetlabs-registry
puppetUpgradeModule puppetlabs-stdlib

puppetUpgradeModule badgerious-windows_env
puppetUpgradeModule liamjbennett-win_facts

#WaitForAnyKey