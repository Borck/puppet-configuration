param (
    [alias('d')]
    [switch] $debug,

    [alias('i')]
    #[parameter(Mandatory=$false)]
    [ValidateSet('Upgrade', 'Install', 'Minimal')]
    [String] $install = 'Upgrade'
);

Set-Location $PSScriptRoot
. .\scripts\functions.ps1

EnsureAdmin


Write-Host "#################################"
Write-Host "######## Set up system ##########"
Write-Host "#################################"
Write-Host ""
Write-Host "This script may install a lots of software, which can take a while ..."
Write-Host "Mode: $install"
Write-Host ""

if($install -eq 'Upgrade'){
  EnsureChoco
  
  Write-Host "Update windows"
  UpgradeChocoPackage pswindowsupdate
  Get-WUInstall
  
  Write-Host "Upgrade required software"
  UpgradeChocoPackage puppet-agent
} elseif ($install -eq 'Install') {
  EnsureChoco
  
  Write-Host "Install required software"
  EnsureChocoPackage puppet-agent
}


$puppetCmd = "puppet apply --modulepath=`"$PSScriptRoot/environments/production/modules`""
if ($debug) {
  $puppetCmd += " --debug"          
}
$puppetCmd += " `"$PSScriptRoot/environments/production/manifests/site.pp`""

Write-Host "Run puppet setup"
Write-Host $puppetCmd

Invoke-Expression "& $puppetCmd"

#WaitForAnyKey
