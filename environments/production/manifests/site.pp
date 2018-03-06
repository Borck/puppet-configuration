node default {
  # New modules and packages can be found here
  # https://forge.puppet.com/
  # https://chocolatey.org/


  if $::kernel == 'windows' {
    ###########################################################################
    ########## Package repositories ###########################################
    ###########################################################################

    # set chocolatey as default package provider
    include chocolatey
    Package { provider => chocolatey, }


    ###########################################################################
    ########## Version control ################################################
    ###########################################################################

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

    # installing tortoisegit can fail if non-package-version is installed
    package { 'tortoisegit': ensure => latest, }

    package { 'tortoisesvn': ensure => latest, }

    package { 'sourcetree': ensure => latest, }



    ###########################################################################
    ########## Visual Studio Code + NotepadReplacer ###########################
    ###########################################################################
    # code for Visual Studio (not Visual Studio Code is at the and of this script)

    package { 'visualstudiocode': ensure => latest, install_options => ['/NoDesktopIcon', '/NoQuicklaunchIcon'], }

    #https://forge.puppet.com/tragiccode/vscode
    # class { 'vscode':
    #   package_ensure              => 'present',
    #   #vscode_download_url           => 'https://company-name.s3.amazonaws.com/binaries/vscode-latest.exe',
    #   #vscode_download_absolute_path => 'C:\\Windows\\Temp',
    #   create_desktop_icon         => false,
    #   create_quick_launch_icon    => false,
    #   create_context_menu_files   => true,
    #   create_context_menu_folders => true,
    #   add_to_path                 => true,
    #   #icon_theme                    => 'vs-seti',
    #   #color_theme                   => 'Monokai Dimmed',
    # }

    # vscode_extension { 'jpogran.puppet-vscode': ensure  => 'present', require => Class['vscode'], }
    # vscode_extension { 'ms-vscode.csharp': ensure  => 'present', require => Class['vscode'], }
    # vscode_extension { 'Gimly81.matlab': ensure  => 'present', require => Class['vscode'], }
    # vscode_extension { 'Lua': ensure  => 'present', require => Class['vscode'], }

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
    ########## Development ####################################################
    ###########################################################################

    package { 'jdk8': ensure => latest, }
    package { 'eclipse': ensure => latest, install_options => ['--params', '"/Multi-User"'], }

    package { 'make': ensure => present, }
    package { 'cmake': ensure => latest, install_options => ['--installargs', '"DESKTOP_SHORTCUT_REQUESTED=0"'], }

    package { 'virtualbox': ensure => latest, install_options => ['/NoDesktopShortcut', '/NoQuickLaunch'], }
    # virtualbox.extensionpack is included in package virtualbox
    # package { 'virtualbox.extensionpack': ensure => latest, }

    package { 'sandboxie': ensure => latest, }

    package { 'hxd': ensure => present, }

    # inspecting PE formatted binaries such aswindows EXEs and DLLs. 
    package { 'pestudio': ensure => present, }
    
    package { 'regfromapp': ensure => present, }

    package { 'Sysinternals': ensure => present, }



    ###########################################################################
    ########## Networking #####################################################
    ###########################################################################

    package { 'putty': ensure => latest, }
    package { 'winscp': ensure => latest, }
    package { 'wireshark': ensure => latest, }
    package { 'CloseTheDoor': ensure => present, } # close tcp/udp ports

    package { 'curl': ensure => present, }
    package { 'wget': ensure => present, }



    ###########################################################################
    ########## Media tools ####################################################
    ###########################################################################

    package { 'caesium.install': ensure => present, }
    package { 'inkscape': ensure => latest, }
    package { 'handbrake': ensure => present, }

    package { 'vlc': ensure => latest, }
    registry_key { 'HKCR\Directory\shell\AddToPlaylistVLC': ensure => present, }
    registry_value { 'HKCR\Directory\shell\AddToPlaylistVLC\LegacyDisable': ensure => present, type => string, }
    registry_key { 'HKCR\Directory\shell\PlayWithVLC': ensure => present, }
    registry_value { 'HKCR\Directory\shell\PlayWithVLC\LegacyDisable': ensure => present, type => string, }

    package { 'itunes': ensure => latest, }
    package { 'mp3tag': ensure => present, }

    package { 'audacity': ensure => present, }
    package { 'audacity-lame': ensure => present, }

    package { 'adobereader': ensure => absent, } # adobe acrobat is installed
    package { 'Calibre ': ensure => present, } # convert * to  ebook



    ###########################################################################
    ########## Office #########################################################
    ###########################################################################

    package { 'firefox': ensure => present, } #firefox have a very silent update mechanism

    class {'sevenzip': package_ensure => 'latest', package_name => ['7zip'], prerelease => false, }

    package { 'ghostscript': ensure => present, }
    package { 'miktex': ensure => present, }
    package { 'texstudio': ensure => present, }
    package { 'jabref': ensure => present, }


    # package { 'dropbox': ensure => present, }

    package { 'capture2text': ensure => present, } # screenshot to text
    package { 'jcpicker': ensure => present, } # screenshot to text
    package { 'screentogif': ensure => present, }
    package { 'AutoHotKey': ensure => present, }
    
    package { 'bulkrenameutility': ensure => present, }
    package { 'dupeguru': ensure => present, }
    package { 'windirstat': ensure => present, }
    package { 'junction-link-magic': ensure => present, }

    package { 'win32diskimager': ensure => present, }

    # rainmeter is unofficial and not a silent installer
    # package { 'rainmeter': ensure => latest, }

    ###########################################################################
    ########## visual studio + unity ##########################################
    ###########################################################################

    package { 'visualstudio2017enterprise': ensure => present, }

    package { 'visualstudio2017-workload-azure': ensure => present, }
    package { 'visualstudio2017-workload-data': ensure => present, }
    package { 'visualstudio2017-workload-manageddesktop': ensure => present, }
    package { 'visualstudio2017-workload-nativecrossplat': ensure => present, }
    package { 'visualstudio2017-workload-nativedesktop': ensure => present, }
    package { 'visualstudio2017-workload-netcoretools': ensure => present, }
    package { 'visualstudio2017-workload-universal': ensure => present, }
    package { 'visualstudio2017-workload-vctools': ensure => present, }
    package { 'visualstudio2017-workload-visualstudioextension': ensure => present, }

    package { 'visualsvn': ensure => latest, }

    # jetbrains
    package { 'resharper': ensure => latest, }
    package { 'dotpeek': ensure => latest, } # decompiler
    package { 'dotcover': ensure => latest, } # unit test runner and code coverage
    package { 'dottrace': ensure => latest, } # performance profiler
    package { 'dotmemory': ensure => latest, } # memory profiler

    # package { 'unity': ensure => latest, }
    # Game development with Unity workload for Visual Studio 2017
    # package { 'visualstudio2017-workload-managedgame': ensure => latest, }



    ###########################################################################
    ########## System ########################################
    ###########################################################################
    package { 'WindowsRepair': ensure => present, }

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
    # registry_value { 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\AutoCheckSelect': ensure => present, type => dword, data => 0x00000001 }

    # add quick merge to context menu of reg-files
    registry_key   { 'HKCR\regfile\shell\quickmerge\command': ensure => present, }
    registry_value { 'HKCR\regfile\shell\quickmerge\\': ensure => present, type => string, data => 'Zusammenführen (Ohne Bestätigung)' }
    registry_value { 'HKCR\regfile\shell\quickmerge\Extended': ensure => present, type => string, data => '' }
    registry_value { 'HKCR\regfile\shell\quickmerge\NeverDefault': ensure => present, type => string, data => '' }
    registry_value { 'HKCR\regfile\shell\quickmerge\command\\': ensure => present, type => string, data => 'regedit.exe /s "%1"' }

    # add 'Restart Explorer' to context menu of desktop
    registry_key   { 'HKCR\DesktopBackground\Shell\Restart Explorer\command': ensure => present, }
    registry_value { 'HKCR\DesktopBackground\Shell\Restart Explorer\icon': ensure => present, type => string, data => 'explorer.exe' }
    registry_value { 'HKCR\DesktopBackground\Shell\Restart Explorer\command\\': ensure => present, type => string, data => 'TSKILL EXPLORER' }

    # remove 'Add to library' from context menu
    registry_key   { 'HKCR\HKEY_CLASSES_ROOT\Folder\ShellEx\ContextMenuHandlers\Library Location': ensure => absent, }
    # backup:
    # registry_value { 'HKCR\HKEY_CLASSES_ROOT\Folder\ShellEx\ContextMenuHandlers\Library Location\\': ensure => present, type => string, data => '{3dad6c5d-2167-4cae-9914-f99e41c12cfa}' }


    # keyboard: remap capslock to shift
    registry_value { 'HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout\Scancode Map': ensure => present, type => binary, data => '00 00 00 00 00 00 00 00 02 00 00 00 2a 00 3a 00 00 00 00 00' }

    # Disable AutoPlay for removable media drives for CurrentUser
    registry_value { 'HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\NoDriveTypeAutoRun': ensure => present, type => dword, data => 0x000000b5,  }

    # Hide_Message_-_“Es_konnten_nicht_alle_Netzlaufwerke_wiederhergestellt_werden”
    registry_value { 'HKLM\SYSTEM\CurrentControlSet\Control\NetworkProvider\RestoreConnection': ensure => present, type => dword, data => '0x00000000' }

    # Remove 'Shortcut' from new links
    # registry_value { 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\link': ensure => present, type => binary, data => '00 00 00 00' }
    # backup: data => '1e 00 00 00'

  }
}
