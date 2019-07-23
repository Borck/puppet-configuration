$ppModulePath = "`"$PSScriptRoot\environments\production\modules`""

function puppetUpgradeModule($moduleName){
   puppet module upgrade $moduleName --force --modulepath $ppModulePath   
}


puppetUpgradeModule puppetlabs-chocolatey
puppetUpgradeModule puppetlabs-powershell
puppetUpgradeModule puppetlabs-registry
puppetUpgradeModule puppetlabs-stdlib

puppetUpgradeModule badgerious-windows_env
puppetUpgradeModule liamjbennett-win_facts

puppetUpgradeModule ianoberst-xml_fragment
puppetUpgradeModule puppetlabs-inifile
