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


#run puppet setup script
puppet apply --modulepath=./environments/production/modules ./environments/production/manifests/site.pp


