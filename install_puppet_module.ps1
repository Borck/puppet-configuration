$ppModulePath = "`"$PSScriptRoot\environments\production\modules`""

$moduleName = Read-Host -Prompt 'Which puppet module do you want to install, or leave empty to skip'

if (-not $moduleName -eq '') {
   puppet module install $moduleName --force --modulepath $ppModulePath   
}

