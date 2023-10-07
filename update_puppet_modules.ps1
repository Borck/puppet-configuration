$ppModulePath = "`"$PSScriptRoot\environments\production\modules`""

function puppetUpgradeModule($moduleName){
   puppet module upgrade $moduleName --force --modulepath $ppModulePath   
}


puppetUpgradeModule puppetlabs-chocolatey
puppetUpgradeModule puppetlabs-pwshlib
puppetUpgradeModule puppetlabs-powershell
puppetUpgradeModule puppetlabs-registry
puppetUpgradeModule puppetlabs-stdlib
puppetUpgradeModule puppet-windows_env

puppetUpgradeModule ianoberst-xml_fragment
puppetUpgradeModule puppetlabs-inifile
