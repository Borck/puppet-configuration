node default {
  # New modules and packages can be found here
  # https://forge.puppet.com/
  # https://chocolatey.org/


  if $::kernel == 'windows' {
    ###########################################################################
    ########## Package repositories ###########################################
    ###########################################################################
    notice('applying package repositories ...')

    # set chocolatey as default package provider
    include chocolatey
    Package { provider => chocolatey, }


    ###########################################################################
    ########## Version control ################################################
    ###########################################################################
    notice('applying version control tools ...')

    # git
    package { 'git': ensure => latest, }

    # remove git from context menu, tortoisegit will replace it
    registry_key { 'HKCR\Directory\shell\git_gui': ensure => present, }
    registry_value { 'HKCR\Directory\shell\git_gui\LegacyDisable': ensure => present, type => string, }
    registry_key { 'HKCR\Directory\shell\git_shell': ensure => present, }
    registry_value { 'HKCR\Directory\shell\git_shell\LegacyDisable': ensure => present, type => string, }
    registry_key { 'HKCR\Directory\Background\shell\git_gui': ensure => present, }
    registry_value { 'HKCR\Directory\Background\shell\git_gui\LegacyDisable': ensure => present, type => string, }
    registry_key { 'HKCR\Directory\Background\shell\git_shell': ensure => present, }
    registry_value { 'HKCR\Directory\Background\shell\git_shell\LegacyDisable': ensure => present, type => string, }


    package { 'tortoisegit': ensure => latest, }
    package { 'tortoisesvn': ensure => latest, }




    ###########################################################################
    ########## Visual Studio Code + NotepadReplacer ###########################
    ###########################################################################
    # code for Visual Studio (not Visual Studio Code is at the and of this script)
    notice('applying Visual Studio Code ...')

    package { 'visualstudiocode': ensure => latest, }

    # preferred symlink syntax
    file { 'C:\ProgramData\NotepadReplacer':
      ensure => 'directory',
    }

    file { 'C:\ProgramData\NotepadReplacer\notepad.exe':
      ensure => 'link',
      target => 'C:\Program Files\Microsoft VS Code\code.exe',
    }

    package { 'notepadreplacer':
      ensure          => installed,
      provider        => chocolatey,
    #  install_options => ['/notepad="C:\Program', 'Files\Notepad++\notepad++.exe"', '/verysilent'],
      install_options => ['-installarguments', '"/notepad=C:\ProgramData\NotepadReplacer\notepad.exe', '/verysilent"'],
    }



    ###########################################################################
    ########## SSH/FTP ########################################################
    ###########################################################################
    notice('applying SSH/FTP tools ...')

    package { 'putty': ensure => latest, }
    package { 'winscp': ensure => latest, }


    ###########################################################################
    ########## Others #########################################################
    ###########################################################################
    notice('applying other tools ...')

    package { 'virtualbox': ensure => latest, }
    package { 'virtualbox.extensionpack': ensure => latest, }
    package { 'jdk8': ensure => latest, }


    class {'sevenzip':
      package_ensure => 'latest',
      package_name   => ['7zip'],
      prerelease     => false,
    }

    package { 'vlc': ensure => latest, }
    registry_key { 'HKCR\Directory\shell\AddToPlaylistVLC': ensure => present, }
    registry_value { 'HKCR\Directory\shell\AddToPlaylistVLC\LegacyDisable': ensure => present, type => string, }
    registry_key { 'HKCR\Directory\shell\PlayWithVLC': ensure => present, }
    registry_value { 'HKCR\Directory\shell\PlayWithVLC\LegacyDisable': ensure => present, type => string, }

    ###########################################################################
    ########## IDE's ##########################################################
    ###########################################################################
    #notice('applying visual studio ...')

    #https://forge.puppet.com/puppet/visualstudio
    #Only Supports 2012?
    #Install module on server with: puppet module install puppet-visualstudio --version 3.0.1
    /*visualstudio { 'visual studio':
      ensure  => present,
      version => '2012',
      edition => 'Enterprise',
      #license_key => 'XXX-XXX-XXX-XXX-XXX',

      #components => ?
      #The list components, tools and utilities that can be installed as part of the visual studio installation.

      #deployment_root => ?
      #Network location where the visual studio packages are located
    }*/

#    package { 'visualstudio2017enterprise': ensure => latest, }
#    package { 'visualsvn': ensure => latest, }
#    package { 'resharper': ensure => latest, }

#    package { 'unity': ensure => latest, }



    ###########################################################################
    ########## Context menu extensions ########################################
    ###########################################################################

    #add 'command prompt' to context menu of folders
    registry_key   { 'HKCR\Directory\ContextMenus\MenuCmd\shell\open\command': ensure => present, }
    registry_value { 'HKCR\Directory\ContextMenus\MenuCmd\shell\open\MUIVerb': type => string, data => 'Command Prompt' }
    registry_value { 'HKCR\Directory\ContextMenus\MenuCmd\shell\open\Icon': type => string, data => 'cmd.exe' }
    registry_value { 'HKCR\Directory\ContextMenus\MenuCmd\shell\open\command\\': type => string, data => 'cmd.exe /s /k pushd "%V"' }

    registry_key   { 'HKCR\Directory\ContextMenus\MenuCmd\shell\runas\command': ensure => present, }
    registry_value { 'HKCR\Directory\ContextMenus\MenuCmd\shell\runas\MUIVerb': type => string, data => 'Command Prompt Elevated' }
    registry_value { 'HKCR\Directory\ContextMenus\MenuCmd\shell\runas\Icon': type => string, data => 'cmd.exe' }
    registry_value { 'HKCR\Directory\ContextMenus\MenuCmd\shell\runas\HasLUAShield': type => string, data => '' }
    registry_value { 'HKCR\Directory\ContextMenus\MenuCmd\shell\runas\command\\': type => string, data => 'cmd.exe /s /k pushd "%V"' }

    registry_key   { 'HKCR\Directory\shell\01MenuCmd': ensure => present, }
    registry_value { 'HKCR\Directory\shell\01MenuCmd\MUIVerb': type => string, data => 'Command Prompts' }
    registry_value { 'HKCR\Directory\shell\01MenuCmd\Icon': type => string, data => 'cmd.exe' }
    registry_value { 'HKCR\Directory\shell\01MenuCmd\ExtendedSubCommandsKey': type => string, data => 'Directory\\ContextMenus\\MenuCmd' }

    registry_key   { 'HKCR\Directory\Background\shell\01MenuCmd': ensure => present, }
    registry_value { 'HKCR\Directory\Background\shell\01MenuCmd\MUIVerb': type => string, data => 'Command Prompts' }
    registry_value { 'HKCR\Directory\Background\shell\01MenuCmd\Icon': type => string, data => 'cmd.exe' }
    registry_value { 'HKCR\Directory\Background\shell\01MenuCmd\ExtendedSubCommandsKey': type => string, data => 'Directory\\ContextMenus\\MenuCmd' }

    #add 'powershell' to context menu of folders
    registry_key   { 'HKCR\Directory\ContextMenus\MenuPowerShell\shell\open\command': ensure => present, }
    registry_value { 'HKCR\Directory\ContextMenus\MenuPowerShell\shell\open\MUIVerb': type => string, data => 'Powershell' }
    registry_value { 'HKCR\Directory\ContextMenus\MenuPowerShell\shell\open\Icon': type => string, data => 'powershell.exe' }
    registry_value { 'HKCR\Directory\ContextMenus\MenuPowerShell\shell\open\command\\': type => string, data => 'powershell.exe -noexit -command Set-Location "%V"' }

    registry_key   { 'HKCR\Directory\ContextMenus\MenuPowerShell\shell\runas\command': ensure => present, }
    registry_value { 'HKCR\Directory\ContextMenus\MenuPowerShell\shell\runas\MUIVerb': type => string, data => 'Powershell Elevated' }
    registry_value { 'HKCR\Directory\ContextMenus\MenuPowerShell\shell\runas\Icon': type => string, data => 'powershell.exe' }
    registry_value { 'HKCR\Directory\ContextMenus\MenuPowerShell\shell\runas\HasLUAShield': type => string, data => '' }
    registry_value { 'HKCR\Directory\ContextMenus\MenuPowerShell\shell\runas\command\\': type => string, data => 'powershell.exe -noexit -command Set-Location "%V"' }

    registry_key   { 'HKCR\Directory\shell\02MenuPowerShell': ensure => present, }
    registry_value { 'HKCR\Directory\shell\02MenuPowerShell\MUIVerb': type => string, data => 'PowerShell' }
    registry_value { 'HKCR\Directory\shell\02MenuPowerShell\Icon': type => string, data => 'powershell.exe' }
    registry_value { 'HKCR\Directory\shell\02MenuPowerShell\ExtendedSubCommandsKey': type => string, data => 'Directory\\ContextMenus\\MenuPowerShell' }

    registry_key   { 'HKCR\Directory\Background\shell\02MenuPowerShell': ensure => present, }
    registry_value { 'HKCR\Directory\Background\shell\02MenuPowerShell\MUIVerb': type => string, data => 'PowerShell' }
    registry_value { 'HKCR\Directory\Background\shell\02MenuPowerShell\Icon': type => string, data => 'powershell.exe' }
    registry_value { 'HKCR\Directory\Background\shell\02MenuPowerShell\ExtendedSubCommandsKey': type => string, data => 'Directory\\ContextMenus\\MenuPowerShell' }

    ###########################################################################
    ########## File explorer tweaks ###########################################
    ###########################################################################

    # how to hide element in 'This PC': http://www.thewindowsclub.com/remove-the-folders-from-this-pc-windows-10
    # hide 'Documents' in 'This PC'
    registry_value { 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{f42ee2d3-909f-4907-8871-4c22fc0bf756}\PropertyBag\ThisPCPolicy': ensure => present, type => string, data => 'Hide' }
    # hide 'Pictures' in 'This PC'
    registry_value { 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{0ddd015d-b06c-45d5-8c4c-f59713854639}\PropertyBag\ThisPCPolicy': ensure => present, type => string, data => 'Hide' }
    # hide 'Videos' in 'This PC'
    registry_value { 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{35286a68-3c57-41a1-bbb1-0eae73d76c95}\PropertyBag\ThisPCPolicy': ensure => present, type => string, data => 'Hide' }

    #enable checkboxes, see: https://www.tenforums.com/attachments/tutorials/35188d1441136772-turn-off-select-items-using-check-boxes-windows-10-a-select_items_with_check_boxes.png
    # registry_value { 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\AutoCheckSelect': type => dword, data => 0x00000001 }


  }
}
