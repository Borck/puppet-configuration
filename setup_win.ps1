# Get the security principal for the Administrator role
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
if (-Not ($myWindowsPrincipal.IsInRole($adminRole)))
{
   # We are not running "as Administrator" - so relaunch as administrator
   $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
   $newProcess.Arguments = $myInvocation.MyCommand.Definition;
   $newProcess.Verb = "runas";
   [System.Diagnostics.Process]::Start($newProcess);
   exit
}


Write-Host "Set up  basic software"

# Register chocolatey as package sourcesteafind
#register-packagesource -Name chocolatey -Provider PSModule -Trusted -Location http://chocolatey.org/api/v2/ -Verbose

if (-Not (Get-Command choco -errorAction SilentlyContinue))
{
  iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
}

#update windows
choco install pswindowsupdate -y
Get-WUInstall

#install puppet agent
choco install puppet-agent -y

#run puppet setup script
puppet apply --modulepath=./environments/production/modules ./environments/production/manifests/site.pp


