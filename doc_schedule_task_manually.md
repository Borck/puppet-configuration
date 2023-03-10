run cmd as admin

install chocolatey
> choco install nircmd

or

https://www.nirsoft.net/utils/nircmd-x64.zip
https://www.nirsoft.net/utils/nircmd.zip


> taskschd.msc


go to task planing library

Create a task running if computer is idle
nircmd exec hide cmd /c puppet apply --modulepath="D:\Users\Borck\OneDrive - b-tu.de\00_Windows\Puppet/environments/production/modules" "D:\Users\Borck\OneDrive - b-tu.de\00_Windows\Puppet/environments/production/manifests/site.pp"