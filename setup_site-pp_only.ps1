param (
    [alias('d')] [switch] $debug
);

Set-Location $PSScriptRoot
. .\scripts\functions.ps1

EnsureAdmin
EnsureChocoPackage puppet-agent


#run puppet setup script
$puppetArg = "--modulepath=$PSScriptRoot/environments/production/modules"
if ($debug) {
   $puppetArg += " --debug"          
}
$puppetArg += " $PSScriptRoot/environments/production/manifests/site.pp"          

puppet apply $puppetArg


#WaitForAnyKey
