Import-Module $PSScriptRoot/Restart-Host.psm1 -Force

function EnsureAdmin() {
   #Get the security principal for the Administrator role
   $myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
   $myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
   $adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
   $isAdmin=$myWindowsPrincipal.IsInRole($adminRole)
   if (-Not ($isAdmin)) {
      Restart-Host -AsAdministrator -Force
      # script is not running "as Administrator" - so relaunch as administrator
      # $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
      # $newProcess.Arguments = "-noexit -file `"$($MyInvocation.PSCommandPath)`"";
      # $newProcess.Verb = "runas";
      # #echo $newProcess
      # [System.Diagnostics.Process]::Start($newProcess);
      # exit
   }
}

function WaitForAnyKey(){
   Write-Host -NoNewLine 'Press any key to continue...';
   $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

function IsCommandPresent($command){
  return Get-Command choco -errorAction SilentlyContinue
}



$chocoInstalled = IsCommandPresent choco
function EnsureChoco() {
   if (-Not ($chocoInstalled)) {
      Invoke-Expression ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
      $chocoInstalled = IsCommandPresent choco
   }
}

function EnsureChocoPackage($packageName){
  EnsureChoco
  choco install $packageName -y
}

function UpgradeChocoPackage($packageName){
  EnsureChoco
  choco upgrade $packageName -y
}
