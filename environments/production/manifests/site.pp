define reg_ensure_file_ext(String $display_name, String $icon) {
  registry_key   { "HKCR\\${name}file": ensure => present, }
  registry_value { "HKCR\\${name}file\\": type => string, data => $display_name }
  registry_key   { "HKCR\\${name}file\\defaulticon": ensure => present, }
  registry_value { "HKCR\\${name}file\\defaulticon\\": type => string, data => $icon }
  registry_key   { "HKCR\\${name}file\\shell": ensure => present, }
  registry_key   { "HKCR\\.${name}": ensure => present, }
  registry_value { "HKCR\\.${name}\\": type => string, data => "${name}file" }
}

define reg_ensure_file_ext_value(String $value) {
  registry_value { "HKCR\\.${name}": type => string, data => $value }
}

define reg_ensure_archive_ext(String $icondirectory) {
  reg_ensure_file_ext { $name: display_name => "${name} Archive", icon => "${icondirectory}\\${name}.ico" }
  registry_key   { "HKCR\\${name}file\\shell\\open\\command": ensure => present, }
  registry_value { "HKCR\\${name}file\\shell\\": type => string, data => 'open' }
  registry_value { "HKCR\\${name}file\\shell\\open\\command\\": type => string, data => '"C:\\Program Files\\7-Zip\\7zFM.exe" "%1"' }
  registry_value { "HKCR\\${name}file\\shell\\open\\Icon": type => string, data => '"C:\\Program Files\\7-Zip\\7zFM.exe"' }
  registry_value { "HKCR\\.${name}\\PerceivedType": type => string, data => 'compressed' }
}

node default {
  # New modules and packages can be found here
  # https://forge.puppet.com/
  # https://chocolatey.org/

  #include stdlib

  if $::kernel == 'windows' {

    $username = split($identity['user'],'\\\\')[1]
    $user_sid = $windows_sid

    $is_my_pc   = 'borck' in downcase($hostname)
    $is_at_pc   = $hostname =~ /^AT\d+$/
    $is_dev_pc  = $is_my_pc or $is_at_pc
    $is_my_user = 'borck' in downcase($username)


    ###########################################################################
    ########## Package repositories ###########################################
    ###########################################################################

    # set chocolatey as default package provider
    include chocolatey
    Package { provider => chocolatey, }



    ###########################################################################
    ########## Office #########################################################
    ###########################################################################
    if $is_my_user {
      package { 'office365proplus ': ensure => present, }
    }

    package { 'firefox': ensure => present, } #firefox have a very silent update mechanism

    package { 'EdgeDeflector ': ensure => latest, } #redirects URIs to the default browser (caution: menu popup)


    class {'sevenzip': package_ensure => 'latest', package_name => ['7zip'], prerelease => false, }

    package { 'capture2text': ensure => present, } # screenshot to text
    package { 'jcpicker': ensure => present, } # screenshot to text
    package { 'screentogif': ensure => present, }
    package { 'AutoHotKey': ensure => present, }

    package { 'bulkrenameutility': ensure => present, }
    package { 'dupeguru': ensure => present, }

    # rainmeter is unofficial and not a silent installer
    # package { 'rainmeter': ensure => latest, }

    if $is_dev_pc {
      # package { 'cloudstation ': ensure => present, } # Synology Cloud Station Drive, synology drive used instead

      package { 'ghostscript': ensure => present, }
      package { 'miktex': ensure => present, }
      package { 'texstudio': ensure => present, }
      package { 'jabref': ensure => present, }
      package { 'yed': ensure => present, }
      # package { 'dropbox': ensure => present, } # not yet installed
    } else {
      #package { 'googlechrome': ensure => present, }
      package { 'adobereader': ensure => present, }
    }



    ###########################################################################
    ########## Media tools ####################################################
    ###########################################################################

    package { 'vlc': ensure => latest, }
    registry_key { 'HKCR\Directory\shell\AddToPlaylistVLC': ensure => present, }
    registry_value { 'HKCR\Directory\shell\AddToPlaylistVLC\LegacyDisable': ensure => present, type => string, }
    registry_key { 'HKCR\Directory\shell\PlayWithVLC': ensure => present, }
    registry_value { 'HKCR\Directory\shell\PlayWithVLC\LegacyDisable': ensure => present, type => string, }

    # disabled because 'present' and 'latest' causes errors and downloading setup exe each time, which takes around 70 s
    # package { 'inkscape': ensure => present, }

    package { 'caesium.install': ensure => present, }
    file { 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Caesium\Caesium - Image Converter.exe':
      ensure => 'link',
      target => 'C:\\Program Files (x86)\\Caesium\\Caesium.exe',
    }
    file { 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Caesium\Caesium.lnk':
      ensure => absent,
    }

    package { 'handbrake': ensure => present, }
    package { 'FileOptimizer': ensure => present, }

    package { 'audacity': ensure => present, }
    package { 'audacity-lame': ensure => present, }

    package { 'Calibre ': ensure => present, } # convert * to ebook
    
    if $is_my_pc {
      #package { 'itunes': ensure => latest, }  #used MS Store version
      package { 'mp3tag': ensure => present, }

      # package { 'vcredist2008': ensure => present, } # install issue
      package { 'picard': ensure => present, } # MusicBrainz Picard, music tags online grabber, requires 'vcredist2008'

      package { 'mkvtoolnix': ensure => present, }
    }



    ###########################################################################
    ########## Development ####################################################
    ###########################################################################

    package { 'jdk8': ensure => present, }

    if $is_dev_pc {

      package { 'eclipse': ensure => present, install_options => ['--params', '"/Multi-User"'], }

      package { 'make': ensure => present, }
      #package { 'cmake': ensure => latest, install_options => ["--installargs", "'DESKTOP_SHORTCUT_REQUESTED=0'", 
      #  "'ADD_CMAKE_TO_PATH=System'", "'ALLUSERS=1'"], }

      # package { 'virtualbox': ensure => latest, install_options => ['--params', '/NoDesktopShortcut', '/NoQuickLaunch'], }
      # virtualbox.extensionpack is included in package virtualbox
      # package { 'virtualbox.extensionpack': ensure => latest, }

      package { 'sandboxie': ensure => latest, }

      package { 'hxd': ensure => present, }

      # inspecting PE formatted binaries such aswindows EXEs and DLLs. 
      # package { 'pestudio': ensure => present, } # 404

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
      package { 'tortoisegit': ensure => present, }

      package { 'tortoisesvn': ensure => present, }

      package { 'sourcetree': ensure => present, }

      # package { 'python3': ensure => '3.6.0', install_options => ['--params', '/InstallDir', '"c:\\program', 'files\\Python\\Python36"']}
    }



    ###########################################################################
    ########## Visual Studio Code + NotepadReplacer ###########################
    ###########################################################################
    # code for Visual Studio (not Visual Studio Code is at the and of this script)

    package { 'visualstudiocode': ensure => present, install_options => ['--params', "'/NoDesktopIcon", "/NoQuicklaunchIcon'"],}

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
      target => 'C:\\Program Files\\Microsoft VS Code\\code.exe',
      #target => "C:\\Users\\${username}\\AppData\\Local\\Programs\\Microsoft VS Code\\code.exe",
    }

    package { 'notepadreplacer':
      ensure          => installed,
      provider        => chocolatey,
    #  install_options => ['/notepad="C:\Program', 'Files\Notepad++\notepad++.exe"', '/verysilent'],
      install_options => ['-installarguments', '"/notepad=C:\ProgramData\NotepadReplacer\notepad.exe', '/verysilent"'],
    }



    ###########################################################################
    ########## visual studio + unity ##########################################
    ###########################################################################

    if $is_dev_pc {
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

      package { 'visualsvn': ensure => present, }

      # jetbrains
      package { 'resharper': ensure => present, }
      package { 'dotpeek': ensure => present, } # decompiler
      package { 'dotcover': ensure => present, } # unit test runner and code coverage
      package { 'dottrace': ensure => present, } # performance profiler
      package { 'dotmemory': ensure => present, } # memory profiler

      # package { 'unity': ensure => present, } not really required
      # Game development with Unity workload for Visual Studio 2017
      # package { 'visualstudio2017-workload-managedgame': ensure => present, }

      package { 'arduino': ensure => present, }
    }



    ###########################################################################
    ########## Administration #################################################
    ###########################################################################

    package { 'sdio': ensure => present, } # Snappy Driver Installer Origin (open source)


    if $is_my_pc {
      package { 'winaero-tweaker': ensure => present, }
    }


    package { 'curl': ensure => present, }
    package { 'wget': ensure => present, }

    if $is_dev_pc {
      package { 'putty': ensure => latest, }
      package { 'winscp': ensure => latest, }
      package { 'wireshark': ensure => latest, }
      package { 'CloseTheDoor': ensure => present, } # close tcp/udp ports


      package { 'windirstat': ensure => present, }
      package { 'junction-link-magic': ensure => present, }

      #package { 'win32diskimager': ensure => present, }
      package { 'etcher': ensure => present, } # image to usb drive or sd card
      package { 'rufus': ensure => present, } # format/create bootable USB flash drives

      # package { 'driverbooster': ensure => latest, } # checksum error
      package { 'bluescreenview': ensure => present, }
      package { 'regfromapp': ensure => present, }
      package { 'Sysinternals': ensure => present, }
      package { 'windows-repair-toolbox': ensure => present, }
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
    }



    ###########################################################################
    ########## File types #####################################################
    ###########################################################################
    $icons = 'C:\\Windows\\Icons.puppet'
    file { $icons:
      ensure             => present,
      source             => 'puppet:///modules/icons',
      source_permissions => ignore,
      recurse            => true,
      purge              => true,
    }



    ## archives ##

    $icons_archives = "${icons}\\7_zip_filetype_theme___windows_10_by_masamunecyrus-d93yxyk"

    reg_ensure_archive_ext {
        '001' : icondirectory => $icons_archives;
        '7z' : icondirectory => $icons_archives;
        'bz2' : icondirectory => $icons_archives;
        'gz' : icondirectory => $icons_archives;
        'rar' : icondirectory => $icons_archives;
        'tar' : icondirectory => $icons_archives;
    }



    ## graphics ##

    package { 'svg-explorer-extension': ensure => present, }
    reg_ensure_file_ext {       'svg' : display_name => 'Scalable Vector Graphics', icon => "${icons}\\svgfile.ico" }
    reg_ensure_file_ext_value { 'svg\\Content Type'  : value => 'image/svg+xml' }
    reg_ensure_file_ext_value { 'svg\\PerceivedType' : value => 'image' }



    ###########################################################################
    ########## File explorer tweaks ###########################################
    ###########################################################################


    if $is_dev_pc {
      # how to hide element in 'This PC': http://www.thewindowsclub.com/remove-the-folders-from-this-pc-windows-10
      # hide 'Documents' in 'This PC'
      registry_value { 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{f42ee2d3-909f-4907-8871-4c22fc0bf756}\PropertyBag\ThisPCPolicy': ensure => present, type => string, data => 'Hide' }
      # hide 'Pictures' in 'This PC'
      registry_value { 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{0ddd015d-b06c-45d5-8c4c-f59713854639}\PropertyBag\ThisPCPolicy': ensure => present, type => string, data => 'Hide' }
      # hide 'Videos' in 'This PC'

      registry_value { 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{35286a68-3c57-41a1-bbb1-0eae73d76c95}\PropertyBag\ThisPCPolicy': ensure => present, type => string, data => 'Hide' }

      #enable checkboxes, see: https://www.tenforums.com/attachments/tutorials/35188d1441136772-turn-off-select-items-using-check-boxes-windows-10-a-select_items_with_check_boxes.png
      registry_value { "HKU\\${user_sid}\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\AutoCheckSelect": ensure => present, type => dword, data => 0x00000001 }

      # add quick merge to context menu of reg-files
      registry_key   { 'HKCR\regfile\shell\quickmerge\command': ensure => present, }
      registry_value { 'HKCR\regfile\shell\quickmerge\\': ensure => present, type => string, data => 'Zusammenführen (Ohne Bestätigung)' }
      registry_value { 'HKCR\regfile\shell\quickmerge\Extended': ensure => present, type => string, data => '' }
      registry_value { 'HKCR\regfile\shell\quickmerge\NeverDefault': ensure => present, type => string, data => '' }
      registry_value { 'HKCR\regfile\shell\quickmerge\command\\': ensure => present, type => string, data => 'regedit.exe /s "%1"' }

      # add 'Restart Explorer' to context menu of desktop
      registry_key   { 'HKCR\DesktopBackground\Shell\Restart Explorer\command': ensure => present, }
      registry_value { 'HKCR\DesktopBackground\Shell\Restart Explorer\\': ensure => present, type => string, data => 'Explorer neustarten' }
      registry_value { 'HKCR\DesktopBackground\Shell\Restart Explorer\icon': ensure => present, type => string, data => 'explorer.exe' }
      registry_value { 'HKCR\DesktopBackground\Shell\Restart Explorer\command\\': ensure => present, type => string, data => 'TSKILL EXPLORER' }
    }

    if $is_my_user {
      # keyboard: remap capslock to shift
      registry_value { 'HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout\Scancode Map': ensure => present, type => binary, data => '00 00 00 00 00 00 00 00 02 00 00 00 2a 00 3a 00 00 00 00 00' }

      # Hide_Message_-_“Es_konnten_nicht_alle_Netzlaufwerke_wiederhergestellt_werden”
      registry_value { 'HKLM\SYSTEM\CurrentControlSet\Control\NetworkProvider\RestoreConnection': ensure => present, type => dword, data => '0x00000000' }

      # remove 'Add to library' from context menu
      registry_key   { 'HKCR\Folder\ShellEx\ContextMenuHandlers\Library Location': ensure => absent, }
      # backup:
      # registry_value { 'HKCR\Folder\ShellEx\ContextMenuHandlers\Library Location\\': ensure => present, type => string, data => '{3dad6c5d-2167-4cae-9914-f99e41c12cfa}' }

      # remove 'Scan with Windows Defender' from context menu
      registry_key   { 'HKCR\*\shellex\ContextMenuHandlers\EPP': ensure => absent, }
      registry_key   { 'HKCR\Directory\shellex\ContextMenuHandlers\EPP': ensure => absent, }
      # backup:
      # registry_value { 'HKCR\*\ShellEx\ContextMenuHandlers\EPP\\': ensure => present, type => string, data => '{09A47860-11B0-4DA5-AFA5-26D86198A780}' }
      # registry_value { 'HKCR\Directory\ShellEx\ContextMenuHandlers\EPP\\': ensure => present, type => string, data => '{09A47860-11B0-4DA5-AFA5-26D86198A780}' }


      # Disable AutoPlay for removable media drives for CurrentUser
      registry_value { 'HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\NoDriveTypeAutoRun': ensure => present, type => dword, data => 0x000000b5,  }

      # Remove 'Shortcut' from new links
      # registry_value { 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\link': ensure => present, type => binary, data => '00 00 00 00' }
      # backup: data => '1e 00 00 00'

      # remove folders from This PC
      # https://chocolatey.org/packages/desktopicons-winconfig
      package { 'taskbar-winconfig':
        ensure          => present,
        install_options => ['--params', '"\'/LOCKED:yes', '/COMBINED:yes', '/PEOPLE:no', '/TASKVIEW:no', '/STORE:no', '/CORTANA:no\'"'],
      }
      # Remove '3D objects' from This PC
      registry_value { 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}': ensure => absent  }
      registry_value { 'HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}': ensure => absent  }


      # Windows Explorer start to This PC
      registry_value {
        "HKU\\${user_sid}\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\LaunchTo":
        ensure => present, type => dword, data => 0x00000001,  }

      # Add Recycling Bin to This PC
      registry_key   {
        "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\MyComputer\\NameSpace\\{645FF040-5081-101B-9F08-00AA002F954E}":
        ensure => present, }


      # Hide Recycling Bin from desktop (GPO way)
      registry_key   { "HKU\\${user_sid}\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\NonEnum": ensure => present, }
      registry_value {
        "HKU\\${user_sid}\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\NonEnum\\{645FF040-5081-101B-9F08-00AA002F954E}":
        ensure => present, type => dword, data => 0x00000001,  }
    }


    ###########################################################################
    ########## Gaming #########################################################
    ###########################################################################
    if $is_my_pc {
      #package { 'origin': ensure => latest, }
      package { 'steam': ensure => present, }
    }
  }
}
