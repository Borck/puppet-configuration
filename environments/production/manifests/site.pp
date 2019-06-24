define reg_ensure_file_ext(String $display_name, String $icon) {
  registry_key   { "HKCR\\${name}file": ensure => present }
  registry_value { "HKCR\\${name}file\\": type => string, data => $display_name }
  registry_key   { "HKCR\\${name}file\\defaulticon": ensure => present }
  registry_value { "HKCR\\${name}file\\defaulticon\\": type => string, data => $icon }
  registry_key   { "HKCR\\${name}file\\shell": ensure => present }
  registry_key   { "HKCR\\.${name}": ensure => present }
  registry_value { "HKCR\\.${name}\\": type => string, data => "${name}file" }
}

define reg_ensure_file_ext_value(String $value) {
  registry_value { "HKCR\\.${name}": type => string, data => $value }
}

define reg_ensure_archive_ext(String $icondirectory) {
  reg_ensure_file_ext { $name: display_name => "${name} Archive", icon => "${icondirectory}\\${name}.ico" }
  registry_key   { "HKCR\\${name}file\\shell\\open\\command": ensure => present }
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

    $username = $identity['user']
    $hkcu = "HKU\\${identity2['sid']}"

    $is_my_pc   = 'borck' in downcase($hostname)
    $is_at_pc   = $hostname =~ /^AT\d+$/
    $is_dev_pc  = $is_my_pc or $is_at_pc
    $is_my_user = '\\borck' in downcase($username)



    ###########################################################################
    ########## Package repositories ###########################################
    ###########################################################################

    # set chocolatey as default package provider
    include chocolatey
    Package { provider => chocolatey }



    ###########################################################################
    ########## Office #########################################################
    ###########################################################################
    if $is_my_user {
      package { 'office365proplus': ensure => present }
    }

    package { 'firefox': ensure => present } #firefox have a very silent update mechanism

    package { 'EdgeDeflector': ensure => latest } #redirects URIs to the default browser (caution: menu popup)


    class {'sevenzip': package_ensure => 'latest', package_name => ['7zip'], prerelease => false }

    package { 'capture2text': ensure => latest } # screenshot to text
    #package { 'jcpicker': ensure => latest } # installer not working (from 20190605)
    package { 'screentogif': ensure => latest }
    package { 'AutoHotKey': ensure => latest }
    package { 'runasdate': ensure => latest }

    package { 'bulkrenameutility': ensure => latest }
    package { 'dupeguru': ensure => latest }

    # rainmeter is unofficial and not a silent installer
    # package { 'rainmeter': ensure => latest }

    if $is_dev_pc {
      # package { 'cloudstation': ensure => present } # Synology Cloud Station Drive, synology drive used instead

      package { 'ghostscript': ensure => present }
      package { 'miktex': ensure => present }
      package { 'texstudio': ensure => present }
      package { 'jabref': ensure => present }
      package { 'yed': ensure => latest }
      # package { 'dropbox': ensure => present } # not yet installed
    } else {
      #package { 'googlechrome': ensure => present }
      package { 'adobereader': ensure => present }
    }



    ###########################################################################
    ########## Media tools ####################################################
    ###########################################################################

    package { 'vlc': ensure => latest }
    registry_key { 'HKCR\\Directory\\shell\\AddToPlaylistVLC': ensure => present }
    registry_value { 'HKCR\\Directory\\shell\\AddToPlaylistVLC\\LegacyDisable': ensure => present, type => string }
    registry_key { 'HKCR\\Directory\\shell\\PlayWithVLC': ensure => present }
    registry_value { 'HKCR\\Directory\\shell\\PlayWithVLC\\LegacyDisable': ensure => present, type => string }

    # disabled because 'present' and 'latest' causes errors and downloading setup exe each time, which takes around 70 s
    # package { 'inkscape': ensure => present }
    package { 'sketchup': ensure => latest }  # sketchup 2017, last free version

    package { 'caesium.install': ensure => present }
    file { 'C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Caesium\\Caesium - Image Converter.exe':
      ensure => 'link',
      target => 'C:\\Program Files (x86)\\Caesium\\Caesium.exe',
    }
    file { 'C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Caesium\\Caesium.lnk':
      ensure => absent,
    }

    package { 'handbrake': ensure => latest }
    package { 'FileOptimizer': ensure => latest }

    package { 'audacity': ensure => latest }
    package { 'audacity-lame': ensure => latest }

    package { 'Calibre': ensure => latest } # convert * to ebook

    if $is_my_pc {
      #package { 'itunes': ensure => latest }  #used MS Store version
      package { 'mp3tag': ensure => latest }

      # package { 'vcredist2008': ensure => present } # install issue
      package { 'picard': ensure => latest } # MusicBrainz Picard, music tags online grabber, requires 'vcredist2008'

      #package { 'mkvtoolnix': ensure => latest } #not in use
    }



    ###########################################################################
    ########## Development ####################################################
    ###########################################################################

    package { 'jdk8': ensure => present }

    if $is_dev_pc {

      package { 'eclipse': ensure => '4.10', install_options => ['--params', '"/Multi-User"'] }

      package { 'make': ensure => present }
      #package { 'cmake': ensure => latest, install_options => ["--installargs", "'DESKTOP_SHORTCUT_REQUESTED=0'", 
      #  "'ADD_CMAKE_TO_PATH=System'", "'ALLUSERS=1'"] }

      # package { 'virtualbox': ensure => latest, install_options => ['--params', '/NoDesktopShortcut', '/NoQuickLaunch'] }
      # virtualbox.extensionpack is included in package virtualbox
      # package { 'virtualbox.extensionpack': ensure => latest }

      package { 'sandboxie': ensure => latest }

      package { 'hxd': ensure => latest }

      # inspecting PE formatted binaries such aswindows EXEs and DLLs. 
      # package { 'pestudio': ensure => present } # 404

      # git
      package { 'git': ensure => latest }
      # remove git from context menu, tortoisegit will replace it
      registry_key { 'HKCR\\Directory\\shell\\git_gui': ensure => present }
      registry_value { 'HKCR\\Directory\\shell\\git_gui\\LegacyDisable': ensure => present, type => string }
      registry_key { 'HKCR\\Directory\\shell\\git_shell': ensure => present }
      registry_value { 'HKCR\\Directory\\shell\\git_shell\\LegacyDisable': ensure => present, type => string }
      registry_key { 'HKCR\\Directory\\Background\\shell\\git_gui': ensure => present }
      registry_value { 'HKCR\\Directory\\Background\\shell\\git_gui\\LegacyDisable': ensure => present, type => string }
      registry_key { 'HKCR\\Directory\\Background\\shell\\git_shell': ensure => present }
      registry_value { 'HKCR\\Directory\\Background\\shell\\git_shell\\LegacyDisable': ensure => present, type => string }

      # installing tortoisegit can fail if non-package-version is installed
      # 'tortoisegit': ensure => latest is causing errors
      package { 'tortoisegit': ensure => present }

      package { 'tortoisesvn': ensure => latest }

      package { 'sourcetree': ensure => present }

      # package { 'python3': ensure => '3.6.0', install_options => ['--params', '/InstallDir', '"c:\\program', 'files\\Python\\Python36"']}
    }



    ###########################################################################
    ########## Visual Studio Code + NotepadReplacer ###########################
    ###########################################################################
    # code for Visual Studio (not Visual Studio Code is at the and of this script)

    # 'visualstudiocode': ensure => latest is causing errors
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

    # vscode_extension { 'jpogran.puppet-vscode': ensure  => 'present', require => Class['vscode'] }
    # vscode_extension { 'ms-vscode.csharp': ensure  => 'present', require => Class['vscode'] }
    # vscode_extension { 'Gimly81.matlab': ensure  => 'present', require => Class['vscode'] }
    # vscode_extension { 'Lua': ensure  => 'present', require => Class['vscode'] }

    # preferred symlink syntax
    file { 'C:\\ProgramData\\NotepadReplacer':
      ensure => 'directory',
    }

    file { 'C:\\ProgramData\\NotepadReplacer\\notepad.exe':
      ensure => 'link',
      target => 'C:\\Program Files\\Microsoft VS Code\\code.exe',
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
      package { 'visualstudio2017enterprise': ensure => present }

      package { 'visualstudio2017-workload-azure': ensure => present }
      package { 'visualstudio2017-workload-data': ensure => present }
      package { 'visualstudio2017-workload-manageddesktop': ensure => present }
      package { 'visualstudio2017-workload-nativecrossplat': ensure => present }
      package { 'visualstudio2017-workload-nativedesktop': ensure => present }
      package { 'visualstudio2017-workload-netcoretools': ensure => present }
      package { 'visualstudio2017-workload-universal': ensure => present }
      package { 'visualstudio2017-workload-vctools': ensure => present }
      package { 'visualstudio2017-workload-visualstudioextension': ensure => present }

      #package { 'visualsvn': ensure => present } #to old, not working with VS2017

      # jetbrains
      package { 'resharper': ensure => present }
      package { 'dotpeek': ensure => present } # decompiler
      package { 'dotcover': ensure => present } # unit test runner and code coverage
      package { 'dottrace': ensure => present } # performance profiler
      package { 'dotmemory': ensure => present } # memory profiler

      package { 'arduino': ensure => present }

      if !$is_my_pc {
        package { 'unity': ensure => present }
        # Game development with Unity workload for Visual Studio 2017
        package { 'visualstudio2017-workload-managedgame': ensure => present }
      }
    }



    ###########################################################################
    ########## Administration #################################################
    ###########################################################################

    package { 'sdio': ensure => latest } # Snappy Driver Installer Origin (open source)


    if $is_my_pc {
      package { 'winaero-tweaker': ensure => latest }
    }


    package { 'curl': ensure => present }
    package { 'wget': ensure => present }

    if $is_dev_pc {
      package { 'putty': ensure => latest }
      package { 'winscp': ensure => latest }
      package { 'wireshark': ensure => latest }
      package { 'CloseTheDoor': ensure => present } # close tcp/udp ports


      package { 'windirstat': ensure => latest }
      package { 'junction-link-magic': ensure => present }

      #package { 'win32diskimager': ensure => present }
      package { 'etcher': ensure => latest } # image to usb drive or sd card
      package { 'rufus': ensure => latest } # format/create bootable USB flash drives

      # package { 'driverbooster': ensure => latest } # checksum error
      package { 'bluescreenview': ensure => present }
      package { 'regfromapp': ensure => present }
      package { 'Sysinternals': ensure => present }
      package { 'windows-repair-toolbox': ensure => present }
      package { 'WindowsRepair': ensure => present }
    }

    ###########################################################################
    ########## Terminal tweaks ################################################
    ###########################################################################

    if $is_dev_pc {
      #add 'command prompt' and powershell to context menu of folders and drives
      #remove obsolete entries
      registry_key   { 'HKCR\\Directory\\ContextMenus\\MenuCmd': ensure => absent }
      registry_key   { 'HKCR\\Directory\\ContextMenus\\MenuPowerShell': ensure => absent }
      registry_key   { 'HKCR\\Directory\\Background\\shell\\01MenuCmd': ensure => absent }
      registry_key   { 'HKCR\\Directory\\Background\\shell\\02MenuPowerShell': ensure => absent }
      registry_key   { 'HKCR\\Directory\\shell\\01MenuCmd': ensure => absent }
      registry_key   { 'HKCR\\Directory\\shell\\02MenuPowerShell': ensure => absent }


      $reg_dir_terminals_icon = 'imageres.dll,-5323'
      $reg_dir_terminals = 'Windows.MultiVerb.cmd;Windows.MultiVerb.cmdPromptAsAdministrator;|;Windows.MultiVerb.Powershell;Windows.MultiVerb.PowershellAsAdmin'

      registry_key   { 'HKCR\\Directory\\Background\\shell\\Terminals':              ensure => present }
      registry_value { 'HKCR\\Directory\\Background\\shell\\Terminals\\Icon':        type => string, data =>  $reg_dir_terminals_icon }
      registry_value { 'HKCR\\Directory\\Background\\shell\\Terminals\\SubCommands': type => string, data => $reg_dir_terminals }
      registry_key   { 'HKCR\\Directory\\shell\\Terminals':                          ensure => present }
      registry_value { 'HKCR\\Directory\\shell\\Terminals\\Icon':                    type => string, data =>  $reg_dir_terminals_icon }
      registry_value { 'HKCR\\Directory\\shell\\Terminals\\SubCommands':             type => string, data => $reg_dir_terminals }
 
      registry_key   { 'HKCR\\Drive\\Background\\shell\\Terminals':              ensure => present }
      registry_value { 'HKCR\\Drive\\Background\\shell\\Terminals\\Icon':        type => string, data =>  $reg_dir_terminals_icon }
      registry_value { 'HKCR\\Drive\\Background\\shell\\Terminals\\SubCommands': type => string, data => $reg_dir_terminals }
      registry_key   { 'HKCR\\Drive\\shell\\Terminals':                          ensure => present }
      registry_value { 'HKCR\\Drive\\shell\\Terminals\\Icon':                    type => string, data =>  $reg_dir_terminals_icon }
      registry_value { 'HKCR\\Drive\\shell\\Terminals\\SubCommands':             type => string, data => $reg_dir_terminals }



      # for powershell scripts (*.ps1): add 'Run as administrator' to context menu
      registry_key   { 'HKCR\\Microsoft.PowerShellScript.1\\Shell\\runas\\command':      ensure => present }
      registry_value { 'HKCR\\Microsoft.PowerShellScript.1\\Shell\\runas\\HasLUAShield': ensure => present, data => '' }
      registry_value { 'HKCR\\Microsoft.PowerShellScript.1\\Shell\\runas\\MUIVerb':      ensure => present, data => '@shell32.dll,-37448' }
      registry_value { 'HKCR\\Microsoft.PowerShellScript.1\\Shell\\runas\\command\\':    ensure => present,
        data   => 'powershell.exe "-Command" "if((Get-ExecutionPolicy ) -ne \'AllSigned\') { Set-ExecutionPolicy -Scope Process Bypass }; & \'%1\'"'
      }
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

    package { 'svg-explorer-extension': ensure => present }
    reg_ensure_file_ext {       'svg' : display_name => 'Scalable Vector Graphics', icon => "${icons}\\svgfile.ico" }
    reg_ensure_file_ext_value { 'svg\\Content Type'  : value => 'image/svg+xml' }
    reg_ensure_file_ext_value { 'svg\\PerceivedType' : value => 'image' }



    ###########################################################################
    ########## This PC tweaks #################################################
    ###########################################################################

    $regkey_hklm_sw_x86 = 'HKLM\\SOFTWARE'
    $regkey_hklm_sw_x64 = 'HKLM\\SOFTWARE\\Wow6432Node'
    $regsubkey_mycomputer_ns = '\\Microsoft\\Windows\\CurrentVersion\\Explorer\\MyComputer\\NameSpace'

    if $is_my_user {
      # Windows Explorer start to This PC
      registry_value {
        "${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\LaunchTo":
        type => dword, data => 0x00000001 }

      # how to hide element in 'This PC': http://www.thewindowsclub.com/remove-the-folders-from-this-pc-windows-10
      $regkeyFolderDesc = 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FolderDescriptions'
      # hide 'Documents' in 'This PC'
      registry_value { "${regkeyFolderDesc}\\{f42ee2d3-909f-4907-8871-4c22fc0bf756}\\PropertyBag\\ThisPCPolicy":
        ensure => present, type => string, data => 'Hide' }
      # hide 'Pictures' in 'This PC'
      registry_value { "${regkeyFolderDesc}\\{0ddd015d-b06c-45d5-8c4c-f59713854639}\\PropertyBag\\ThisPCPolicy":
        ensure => present, type => string, data => 'Hide' }
      # hide 'Videos' in 'This PC'
      registry_value { "${regkeyFolderDesc}\\{35286a68-3c57-41a1-bbb1-0eae73d76c95}\\PropertyBag\\ThisPCPolicy":
        ensure => present, type => string, data => 'Hide' }

      # remove '3D objects'
      registry_key { "${regkey_hklm_sw_x86}${$regsubkey_mycomputer_ns}\\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}": ensure => absent }
      registry_key { "${regkey_hklm_sw_x64}${$regsubkey_mycomputer_ns}\\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}": ensure => absent }

    }

    # ensure 'Recycling Bin'
    registry_key { "${regkey_hklm_sw_x86}${$regsubkey_mycomputer_ns}\\{645FF040-5081-101B-9F08-00AA002F954E}": ensure => present }
    registry_key { "${regkey_hklm_sw_x64}${$regsubkey_mycomputer_ns}\\{645FF040-5081-101B-9F08-00AA002F954E}": ensure => present }

    # ensure 'Desktop'
    registry_key { "${regkey_hklm_sw_x86}${$regsubkey_mycomputer_ns}\\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}": ensure => present }
    registry_key { "${regkey_hklm_sw_x64}${$regsubkey_mycomputer_ns}\\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}": ensure => present }

    # ensure 'Downloads'
    registry_key { "${regkey_hklm_sw_x86}${$regsubkey_mycomputer_ns}\\{374DE290-123F-4565-9164-39C4925E467B}": ensure => present }
    registry_key { "${regkey_hklm_sw_x64}${$regsubkey_mycomputer_ns}\\{374DE290-123F-4565-9164-39C4925E467B}": ensure => present }

    # ensure 'Music'
    registry_key { "${regkey_hklm_sw_x86}${$regsubkey_mycomputer_ns}\\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}": ensure => present }
    registry_key { "${regkey_hklm_sw_x64}${$regsubkey_mycomputer_ns}\\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}": ensure => present }


################################################################################
#                                # RELOCATE SHELL/LIBRARY FOLDERS #	       #
################################################################################
#RELOCATE SHELL FOLDERS TO NEW DRIVE PARTITION: COOKIES | SENDTO | DOCS | FAVS | PICS | MUSIC | VIDEO | TIF | DOWNLOAD | TEMPLATES
#http://www.tweakhound.com/2013/10/22/tweaking-windows-8-1/5/
#[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders]
#"SendTo"="X:\\OFF_SYSTEMDRIVE\\XtremeSend2\\SendTo"
#"Personal"="X:\\OFF_SYSTEMDRIVE\\DOCS"
#"Favorites"="X:\\OFF_SYSTEMDRIVE\\Favs"
#"My Pictures"="X:\\OFF_SYSTEMDRIVE\\Pics"
#"My Music"="X:\\OFF_SYSTEMDRIVE\\Music"
#COPY AND PASTE HEX VALUIE FOR DOWNLOAD SHELL FOLDER {374DE290-123F-4565-9164-39C4925E467B}
#"{374DE290-123F-4565-9164-39C4925E467B}"=hex(2):46,00,3a,00,5c,00,57,00,50,00,\
#  49,00,5c,00,49,00,6e,00,73,00,74,00,61,00,6c,00,6c,00,5c,00,31,00,44,00,6f,\
#  00,77,00,6e,00,6c,00,6f,00,61,00,64,00,73,00,00,00
#"Templates"=hex(2):46,00,3a,00,5c,00,31,00,48,00,4f,00,4d,00,45,00,5c,00,44,00,\
#  4f,00,43,00,53,00,5c,00,54,00,65,00,6d,00,70,00,6c,00,61,00,74,00,65,00,00,\
#00
    ###########################################################################
    ########## File explorer tweaks ###########################################
    ###########################################################################

    if $is_dev_pc {

      #enable checkboxes
      registry_value { "${hkcu}\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\AutoCheckSelect":
        ensure => present, type => dword, data => 0x00000001 }

      # add quick merge to context menu of reg-files
      registry_key   { 'HKCR\\regfile\\shell\\quickmerge\\command': ensure => present }
      registry_value { 'HKCR\\regfile\\shell\\quickmerge\\': ensure => present, type => string, data => 'Zusammenführen (Ohne Bestätigung)' }
      registry_value { 'HKCR\\regfile\\shell\\quickmerge\\Extended': ensure => absent, type => string, data => '' }
      registry_value { 'HKCR\\regfile\\shell\\quickmerge\\NeverDefault': ensure => present, type => string, data => '' }
      registry_value { 'HKCR\\regfile\\shell\\quickmerge\\command\\': ensure => present, type => string, data => 'regedit.exe /s "%1"' }

      # add 'Restart Explorer' to context menu of desktop
      registry_key   { 'HKCR\\DesktopBackground\\Shell\\Restart Explorer\\command': ensure => present }
      registry_value { 'HKCR\\DesktopBackground\\Shell\\Restart Explorer\\': ensure => present, type => string, data => 'Explorer neustarten' }
      registry_value { 'HKCR\\DesktopBackground\\Shell\\Restart Explorer\\icon': ensure => present, type => string, data => 'explorer.exe' }
      registry_value { 'HKCR\\DesktopBackground\\Shell\\Restart Explorer\\command\\': ensure => present, type => string, data => 'TSKILL EXPLORER' }
    }

    if $is_my_user {
      # keyboard: remap capslock to shift
      registry_value { 'HKLM\\SYSTEM\\CurrentControlSet\\Control\\Keyboard Layout\\Scancode Map':
        ensure => present, type => binary, data => '00 00 00 00 00 00 00 00 02 00 00 00 2a 00 3a 00 00 00 00 00' }

      # Hide_Message_-_“Es_konnten_nicht_alle_Netzlaufwerke_wiederhergestellt_werden”
      registry_value { 'HKLM\\SYSTEM\\CurrentControlSet\\Control\\NetworkProvider\\RestoreConnection': ensure => present, type => dword, data => '0x00000000' }

      # remove 'Add to library' from context menu
      registry_key   { 'HKCR\\Folder\\ShellEx\\ContextMenuHandlers\\Library Location': ensure => absent }
      # backup:
      # registry_value { 'HKCR\\Folder\\ShellEx\\ContextMenuHandlers\\Library Location\\': ensure => present, type => string, data => '{3dad6c5d-2167-4cae-9914-f99e41c12cfa}' }

      # remove 'Scan with Windows Defender' from context menu
      registry_key   { 'HKCR\\*\\shellex\\ContextMenuHandlers\\EPP': ensure => absent }
      registry_key   { 'HKCR\\Directory\\shellex\\ContextMenuHandlers\\EPP': ensure => absent }
      registry_key   { 'HKCR\\Drive\\shellex\\ContextMenuHandlers\\EPP': ensure => absent }

      # backup:
      # registry_value { 'HKCR\\*\\ShellEx\\ContextMenuHandlers\\EPP\\': ensure => present, type => string, data => '{09A47860-11B0-4DA5-AFA5-26D86198A780}' }
      # registry_value { 'HKCR\\Directory\\ShellEx\\ContextMenuHandlers\\EPP\\': ensure => present, type => string, data => '{09A47860-11B0-4DA5-AFA5-26D86198A780}' }


      # Disable AutoPlay for removable media drives for CurrentUser
      registry_value { 'HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer\\NoDriveTypeAutoRun':
        ensure => present, type => dword, data => 0x000000b5 }

      # Remove 'Shortcut' from new links
      # registry_value { 'HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\link': ensure => present, type => binary, data => '00 00 00 00' }
      # backup: data => '1e 00 00 00'

      # remove folders from This PC
      # https://chocolatey.org/packages/desktopicons-winconfig
      package { 'taskbar-winconfig':
        ensure          => present,
        install_options => ['--params', '"\'/LOCKED:yes', '/COMBINED:yes', '/PEOPLE:no', '/TASKVIEW:no', '/STORE:no', '/CORTANA:no\'"'],
      }

      

            # Hide Recycling Bin from desktop (GPO way)
      registry_key   { "${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\NonEnum": ensure => present }
      registry_value {
        "${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\NonEnum\\{645FF040-5081-101B-9F08-00AA002F954E}":
        type => dword, data => 0x00000001 }
    }

    

    ###############################################################################
                                    # REGISTER / UNREGISTER  DLL & OCX FILE #	   #
    ###############################################################################
    #http://www.eightforums.com/tutorials/40512-register-unregister-context-menu-dll-ocx-files.html
    if $is_dev_pc {
      registry_key   { 'HKEY_CLASSES_ROOT\\dllfile\\shell\\Register\\command': ensure => present }
      registry_value   { 'HKEY_CLASSES_ROOT\\dllfile\\shell\\Register\\command': type => string, data => 'regsvr32.exe "%L"' }
      registry_key   { 'HKEY_CLASSES_ROOT\\dllfile\\shell\\Unregister\\command': ensure => present }
      registry_value   { 'HKEY_CLASSES_ROOT\\dllfile\\shell\\Unregister\\command': type => string, data => 'regsvr32.exe /u %L' }

      registry_key   { 'HKEY_CLASSES_ROOT\\ocxfile\\shell\\Register\\command': ensure => present }
      registry_value   { 'HKEY_CLASSES_ROOT\\ocxfile\\shell\\Register\\command': type => string, data => 'regsvr32.exe "%L"' }
      registry_key   { 'HKEY_CLASSES_ROOT\\ocxfile\\shell\\Unregister\\command': ensure => present }
      registry_value   { 'HKEY_CLASSES_ROOT\\ocxfile\\shell\\Unregister\\command': type => string, data => 'regsvr32.exe /u %L' }
    }

    ###########################################################################
    ########## Gaming #########################################################
    ###########################################################################
    if $is_my_pc {
      #package { 'origin': ensure => latest }
      package { 'steam': ensure => present }
    }
  }
}
