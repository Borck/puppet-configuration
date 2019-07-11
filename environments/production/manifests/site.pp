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

    ###########################################################################
    ########## TODO ###########################################################
    ###########################################################################

    #https://stackoverflow.com/questions/24579193/how-do-i-automatically-keep-all-locally-installed-chocolatey-packages-up-to-date



    ###########################################################################
    ########## Configuration ##################################################
    ###########################################################################

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
    if $is_my_pc {
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

    # rainmeter is unofficial and not a silent installer
    # package { 'rainmeter': ensure => latest }

    if $is_dev_pc {
      # package { 'cloudstation': ensure => present } # Synology Cloud Station Drive, synology drive used instead

      package { 'ghostscript': ensure => present }
      package { ['miktex', 'texstudio', 'jabref']: ensure => present }
      package { 'yed': ensure => latest }
    } else {
      #package { 'googlechrome': ensure => present }
      #package { 'adobereader': ensure => present } 
    }


    if $::architecture == 'x64' {
      # [..] index Adobe PDF documents using Microsoft indexing clients. This allows the user to easily search for text
      # within Adobe PDF documents. [..]
      package { 'pdf-ifilter-64': ensure => latest }
    }


    ###########################################################################
    ########## File Management ################################################
    ###########################################################################

    package { 'dupeguru': ensure => latest }
    package { 'lockhunter': ensure => latest }
    package { 'windirstat': ensure => latest }
    package { 'junction-link-magic': ensure => present }
    package { 'bulkrenameutility': ensure => latest }
    registry_key { [
        'HKEY_CLASSES_ROOT\\*\\shellex\\ContextMenuHandlers\\BRUMenuHandler',
        'HKEY_CLASSES_ROOT\\Directory\\shellex\\ContextMenuHandlers\\BRUMenuHandler',
        'HKEY_CLASSES_ROOT\\Drive\\shellex\\ContextMenuHandlers\\BRUMenuHandler',
      ] : ensure => absent, require => Package['bulkrenameutility'] }
    #registry_value {"HKEY_CLASSES_ROOT\\Directory\\shellex\\ContextMenuHandlers\\BRUMenuHandler\\": type => string, data => '{5D924130-4CB1-11DB-B0DE-0800200C9A66}'}


    ###########################################################################
    ########## Media tools/tweaks #############################################
    ###########################################################################

    package { 'vlc': ensure => latest }
    if $is_my_user {
      registry_value { [
          'HKCR\\Directory\\shell\\AddToPlaylistVLC\\LegacyDisable',
          'HKCR\\Directory\\shell\\PlayWithVLC\\LegacyDisable'
        ]: ensure => present, type => string, require => Package['vlc'] }
    }

    package { 'sketchup': ensure => latest }  # sketchup 2017, last free version

    package { 'caesium.install': ensure => present }
    file { 'caesium.shortcut':
      ensure  => present,
      path    => 'C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Caesium\\Caesium - Image Converter.lnk',
      source  => "puppet:///modules/windows_tool_helper/caesium/Caesium_${::architecture}.lnk",
      require => Package['caesium.install']
    }
    file { 'C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Caesium\\Caesium.lnk':
      ensure => absent,
    }

    package { 'handbrake': ensure => latest }
    package { 'FileOptimizer': ensure => latest }

    package { ['audacity', 'audacity-lame']: ensure => latest }

    if $is_my_pc {
      package { 'Calibre': ensure => latest } # convert * to ebook

      #package { 'itunes': ensure => latest }  #used MS Store version
      package { 'mp3tag':
        ensure          => latest,
        install_options => ['--package-parameters=\'"/NoDesktopShortcut', '/NoContextMenu"\'']
      }
      registry_key {'HKCR\\Directory\\shellex\\ContextMenuHandlers\\Mp3tagShell': ensure => absent, require => Package['mp3tag']}

      # package { 'vcredist2008': ensure => present } # install issue
      package { 'picard': ensure => latest } # MusicBrainz Picard, music tags online grabber, requires 'vcredist2008'

      #package { 'mkvtoolnix': ensure => latest } #not in use
    }

    if $is_my_user {
      #nuke Windows Media Player
      registry_value { [
          'HKCR\\SystemFileAssociations\\Directory.Audio\\shell\\Enqueue\\LegacyDisable',
          'HKCR\\SystemFileAssociations\\Directory.Audio\\shell\\Play\\LegacyDisable',
          'HKCR\\SystemFileAssociations\\Directory.Image\\shell\\Enqueue\\LegacyDisable',
          'HKCR\\SystemFileAssociations\\Directory.Image\\shell\\Play\\LegacyDisable',
          #'HKCR\\SystemFileAssociations\\Directory.Video\\shell\\Enqueue\\LegacyDisable',
          #'HKCR\\SystemFileAssociations\\Directory.Video\\shell\\Play\\LegacyDisable',
          'HKCR\\SystemFileAssociations\\audio\\shell\\Enqueue\\LegacyDisable',
          'HKCR\\SystemFileAssociations\\audio\\shell\\Play\\LegacyDisable',
          #'HKCR\\SystemFileAssociations\\video\\shell\\Enqueue\\LegacyDisable',
          #'HKCR\\SystemFileAssociations\\video\\shell\\Play\\LegacyDisable',
        ]: ensure => present, type => string }
      registry_key { 'HKCR\\SystemFileAssociations\\Directory.Audio\\shellex\\ContextMenuHandlers\\PlayTo': ensure => absent }
      #registry_value { 'HKCR\\SystemFileAssociations\\Directory.Audio\\shellex\\ContextMenuHandlers\\PlayTo\\': 
        #ensure => absent, type => string, data => '{7AD84985-87B4-4a16-BE58-8B72A5B390F7}' }
    }

    ###########################################################################
    ########## SVG/Inkscape ###################################################
    ###########################################################################
    package { 'inkscape': ensure => latest }
    $inkscape = "C:\\Program Files\\inkscape\\inkscape.exe"
    registry_key   {'HKCR\\Applications\\inkscape.exe\\shell\\open\\command': ensure => present}
    registry_value {'HKCR\\Applications\\inkscape.exe\\shell\\open\\command\\': type => string, data => "\"${inkscape}\", \"%1\""}
    registry_value {'HKCR\\Applications\\inkscape.exe\\shell\\open\\icon': type => string, data => "\"${inkscape}\", 0"}

    registry_key {'HKCR\\Applications\\inkscape.exe\\shell\\convertmenu': ensure => present}
    registry_value {'HKCR\\Applications\\inkscape.exe\\shell\\convertmenu\\ExtendedSubCommandsKey': type => string, data => 'Applications\\inkscape.exe\\ContextMenus\\converters'}
    registry_value {'HKCR\\Applications\\inkscape.exe\\shell\\convertmenu\\': type => string, data => 'Convert'}

    registry_key {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPng\\command': ensure => present}
    registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPng\\icon': type => string, data => "\"${inkscape}\", 0"}
    registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPng\\': type => string, data => 'Convert to PNG'}
    registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPng\\command\\': type => string, data => "\"${inkscape}\" -z \"%1\" -e \"%1.png\""}

    registry_key {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPs\\command': ensure => present}
    registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPs\\icon': type => string, data => "\"${inkscape}\", 0"}
    registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPs\\': type => string, data => 'Convert to PS'}
    registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPs\\command\\': type => string, data => "\"${inkscape}\" -z \"%1\" -P \"%1.ps\""}

    registry_key {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToEps\\command': ensure => present}
    registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToEps\\icon': type => string, data => "\"${inkscape}\", 0"}
    registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToEps\\': type => string, data => 'Convert to EPS'}
    registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToEps\\command\\': type => string, data => "\"${inkscape}\" -z \"%1\" -E \"%1.eps\""}

    registry_key {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPdf\\command': ensure => present}
    registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPdf\\icon': type => string, data => "\"${inkscape}\", 0"}
    registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPdf\\': type => string, data => 'Convert to PDF'}
    registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPdf\\command\\': type => string, data => "\"${inkscape}\" -z \"%1\" -A \"%1.pdf\""}



    ###########################################################################
    ########## Text tweaks ####################################################
    ###########################################################################

    $default_text_editor = 'C:\\Program Files\\Microsoft VS Code\\code.exe'
    #$default_text_editor = '%SystemRoot%\system32\NOTEPAD.EXE'

    # change *.txt file association
    registry_key   {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FileExts\\.txt\\UserChoice": ensure => present}
    registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FileExts\\.txt\\UserChoice\\Hash": type => string, data => 'hK1YV2FCtgs='}
    registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FileExts\\.txt\\UserChoice\\ProgId": type => string, data => 'Applications\\code.exe'}

    $notepad_replace_helperdir = 'C:\\ProgramData\\NotepadReplacer'
    $notepad_replace_helperlink = "${notepad_replace_helperdir}\\notepad.exe"
    # preferred symlink syntax
    file { $notepad_replace_helperdir: ensure => 'directory', }
    file { $notepad_replace_helperlink: ensure => 'link', target => $default_text_editor }

    package { 'notepadreplacer':
      ensure          => present,
      install_options => ['-installarguments', "\"/notepad=${notepad_replace_helperlink}", '/verysilent"'],
    }

    registry_value {'HKCR\\SystemFileAssociations\\text\\shell\\open\\icon': type => string, data => $notepad_replace_helperlink}
    registry_value {'HKCR\\SystemFileAssociations\\text\\shell\\edit\\LegacyDisable': type => string, data => ''}

    #comment code, because of changed 'Open With' setting above for *.txt files
    #registry_value {'HKCR\\txtfile\\shell\\open\\icon': type => string, data => $notepad_replace_helperlink}
    #registry_value {'HKCR\\txtfile\\shell\\print\\LegacyDisable': type => string, data => ''}
    #registry_value {'HKCR\\txtfile\\shell\\printto\\LegacyDisable': type => string, data => ''}




    ###########################################################################
    ########## Development ####################################################
    ###########################################################################

    package { 'jdk8': ensure => present } # 'ensure => latest' may dumping your system, 20190628

    if $is_dev_pc {
      #not required yet
      #package { 'eclipse': ensure => '4.10', install_options => ['--params', '"/Multi-User"'] }

      package { 'make': ensure => present }
      #package { 'cmake': ensure => latest, install_options => ["--installargs", "'DESKTOP_SHORTCUT_REQUESTED=0'", 
      #  "'ADD_CMAKE_TO_PATH=System'", "'ALLUSERS=1'"] }

      # package { 'virtualbox': ensure => latest, install_options => ['--params', '/NoDesktopShortcut', '/NoQuickLaunch'] }
      # virtualbox.extensionpack is included in package virtualbox
      # package { 'virtualbox.extensionpack': ensure => latest }

      package { 'sandboxie': ensure => latest }

      package { 'hxd': ensure => latest }

      # inspecting PE formatted binaries such aswindows EXEs and DLLs. 
      # package { 'pestudio': ensure => present } # deprecated

      # git
      package { 'git': ensure => latest }
      # remove git from context menu, tortoisegit will replace it

      registry_key { [
        'HKCR\\Directory\\shell\\git_gui',
        'HKCR\\Directory\\shell\\git_shell',
        'HKCR\\Directory\\Background\\shell\\git_gui',
        'HKCR\\Directory\\Background\\shell\\git_shell',
        ]: ensure => present, require => Package['git'] }
      registry_value { [
        'HKCR\\Directory\\shell\\git_gui\\LegacyDisable',
        'HKCR\\Directory\\shell\\git_shell\\LegacyDisable',
        'HKCR\\Directory\\Background\\shell\\git_gui\\LegacyDisable',
        'HKCR\\Directory\\Background\\shell\\git_shell\\LegacyDisable',
        ]: ensure => present, type => string, require => Package['git'] }

      # installing tortoisegit can fail if non-package-version is installed
      # 'tortoisegit': ensure => latest is causing errors
      package { 'tortoisegit': ensure => present }
      package { 'tortoisesvn': ensure => latest }
      package { 'sourcetree': ensure => present }

      # package { 'python3': ensure => '3.6.0', install_options => ['--params', '/InstallDir', '"c:\\program', 'files\\Python\\Python36"']}
    }



    ###########################################################################
    ########## Visual Studio Code #############################################
    ###########################################################################
    # code for Visual Studio (not Visual Studio Code is at the and of this script)

    # 'visualstudiocode': ensure => latest is causing errors
    package { 'vscode':
      ensure          => present,
      install_options => ['--params', '"/NoDesktopIcon', '/NoQuicklaunchIcon"'], # ', '/NoContextMenuFiles', '/NoContextMenuFolders
    }

    registry_value { 'HKCR\\Applications\\Code.exe\\shell\\open\\icon':
      ensure  => present,
      type    => string,
      data    => '"C:\\Program Files\\Microsoft VS Code\\Code.exe", 0',
      require => Package['vscode']}

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




    ###########################################################################
    ########## visual studio + unity ##########################################
    ###########################################################################

    if $is_dev_pc {
      package { [
        'visualstudio2017enterprise',
        'visualstudio2017-workload-data',
        'visualstudio2017-workload-manageddesktop',
        'visualstudio2017-workload-nativecrossplat',
        'visualstudio2017-workload-nativedesktop',
        'visualstudio2017-workload-netcoretools',
        #'visualstudio2017-workload-universal',
        'visualstudio2017-workload-vctools',
        'visualstudio2017-workload-visualstudioextension'
        ]: ensure => present }

      # creating windows installers
      #package { 'wixtoolset': ensure => present } # manual installation of *.vsix failed
      #package { 'visualsvn': ensure => present } #to old, not working with VS2017

      # jetbrains
      package { ['resharper', 'dotpeek', 'dotcover', 'dottrace', 'dotmemory']: ensure => present }

      if $is_my_pc {
        package { 'arduino': ensure => present }
      } else {
        package { ['unity', 'unity-standard-assets']: ensure => present }
        package { 'visualstudio2017-workload-managedgame':
          ensure  => present,
          require => [
            Package['visualstudio2017enterprise'],
            Package['unity'],
          ],
        }
      }
    }

    # not needed yet: hide 'Open with Visual Studio' in folders context menu
    # registry_value {"HKEY_CLASSES_ROOT\\Directory\\shell\\AnyCode\\LegacyDisable": type => string, data => ''}
    # registry_value {"HKEY_CLASSES_ROOT\\Directory\\Background\\shell\\AnyCode\\LegacyDisable": type => string, data => ''}


    ###########################################################################
    ########## Gaming #########################################################
    ###########################################################################
    if $is_my_pc {
      #package { 'origin': ensure => latest }
      package { 'steam': ensure => present }
    }


    ###########################################################################
    ########## Administration #################################################
    ###########################################################################
    package { 'sdio': ensure => latest } # Snappy Driver Installer Origin (open source)

    if $is_my_pc {
      package { 'winaero-tweaker': ensure => latest }
    }

    package { ['curl', 'wget']: ensure => present }

    if $is_dev_pc {
      package { 'putty': ensure => latest }
      package { 'winscp': ensure => latest }
      package { 'wireshark': ensure => latest }
      package { 'CloseTheDoor': ensure => present } # close tcp/udp ports

      #package { 'win32diskimager': ensure => present }
      package { 'etcher': ensure => latest } # image to usb drive or sd card
      package { 'rufus': ensure => latest } # format/create bootable USB flash drives

      # package { 'driverbooster': ensure => latest } # checksum error
      package { 'bluescreenview': ensure => present }
      package { 'regfromapp': ensure => present }
      package { 'Sysinternals': ensure => present }
      #package { 'windows-repair-toolbox': ensure => present }
      #package { 'WindowsRepair': ensure => present }
    }

    ###########################################################################
    ########## File Explorer Tweaks ###########################################
    ###########################################################################

    if $is_dev_pc {
      #add 'command prompt' and powershell to context menu of folders and drives
      registry_key   { [
          'HKCR\\Directory\\Background\\shell\\Terminals',
          'HKCR\\Directory\\shell\\Terminals',
          'HKCR\\Drive\\Background\\shell\\Terminals',
          'HKCR\\Drive\\shell\\Terminals'
        ]: ensure => present }
      registry_value { [
          'HKCR\\Directory\\Background\\shell\\Terminals\\Icon',
          'HKCR\\Directory\\shell\\Terminals\\Icon',
          'HKCR\\Drive\\Background\\shell\\Terminals\\Icon',
          'HKCR\\Drive\\shell\\Terminals\\Icon'
        ]: type => string, data =>  'imageres.dll,-5323' }
      registry_value { [
          'HKCR\\Directory\\Background\\shell\\Terminals\\SubCommands',
          'HKCR\\Directory\\shell\\Terminals\\SubCommands',
          'HKCR\\Drive\\Background\\shell\\Terminals\\SubCommands',
          'HKCR\\Drive\\shell\\Terminals\\SubCommands'
        ]: type => string, data => 'Windows.MultiVerb.cmd;Windows.MultiVerb.cmdPromptAsAdministrator;|;Windows.MultiVerb.Powershell;Windows.MultiVerb.PowershellAsAdmin' }


      # for powershell scripts (*.ps1): add 'Run as administrator' to context menu
      registry_key   { 'HKCR\\Microsoft.PowerShellScript.1\\Shell\\runas\\command':      ensure => present }
      registry_value { 'HKCR\\Microsoft.PowerShellScript.1\\Shell\\runas\\HasLUAShield': ensure => present }
      registry_value { 'HKCR\\Microsoft.PowerShellScript.1\\Shell\\runas\\MUIVerb':      ensure => present, data => '@shell32.dll,-37448' }
      registry_value { 'HKCR\\Microsoft.PowerShellScript.1\\Shell\\runas\\command\\':
        ensure => present,
        data   => 'powershell.exe "-Command" "if((Get-ExecutionPolicy ) -ne \'AllSigned\') { Set-ExecutionPolicy -Scope Process Bypass }; & \'%1\'"'
      }
    }

    
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


    if $is_my_user {
      # recycle bin
      # https://www.tenforums.com/tutorials/12479-change-recycle-bin-icon-windows-10-a.html#option1
      # if icons not applied, maybe 'Remove Recycling Bin from Desktop' from GPO have to be disabled,
      # NOTE: the recycling bin can also be remove on 'Configure Desktop Icons' window, [WIN]+[R] and type:
      #       rundll32.EXE shell32.dll,Control_RunDLL desk.cpl,,0
      # NOTE: https://www.windows-faq.de/2017/12/27/papierkorb-symbol-nicht-auf-dem-desktop-anzeigen/ 

      $recyclebin_icons_reg = "${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CLSID\\{645FF040-5081-101B-9F08-00AA002F954E}\\DefaultIcon"
      registry_value { [
        "${recyclebin_icons_reg}\\",
        "${recyclebin_icons_reg}\\full"
        ]: ensure => present, type => string, data => "${icons}\\recycle-bin-full.ico,0" }
      registry_value { "${recyclebin_icons_reg}\\empty": ensure => present, type => string, data => "${icons}\\recycle-bin-empty.ico,0" }

      registry_key   { "${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\NonEnum": ensure => present }
      # set to zero (disabled), because of issues with customized icons
      registry_value { "${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\NonEnum\\{645FF040-5081-101B-9F08-00AA002F954E}":
        type => dword, data => 0x00000000 }
    }

    if $is_dev_pc {
      #take ownership context entry
      # registry_key   {'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore\\shell\\Windows.takeownership.directories\\command': ensure => present}
      # registry_value {'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore\\shell\\Windows.takeownership.directories\\': type => string, data => 'Take Ownership'}
      # registry_value {'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore\\shell\\Windows.takeownership.directories\\NoWorkingDirectory': type => string, data => ''}
      # registry_value {'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore\\shell\\Windows.takeownership.directories\\command\\': type => string, data => 'cmd.exe /c takeown /f "%1" /r /d y && icacls "%1" /grant administrators:F /t'}
      # registry_value {'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore\\shell\\Windows.takeownership.directories\\command\\IsolatedCommand': type => string, data => 'cmd.exe /c takeown /f "%1" /r /d y && icacls "%1" /grant administrators:F /t'}

      # registry_key   {'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore\\shell\\Windows.takeownership.files\\command': ensure => present}
      # registry_value {'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore\\shell\\Windows.takeownership.files\\': type => string, data => 'Take Ownership'}
      # registry_value {'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore\\shell\\Windows.takeownership.files\\NoWorkingDirectory': type => string, data => ''}
      # registry_value {'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore\\shell\\Windows.takeownership.files\\command\\': type => string, data => 'cmd.exe /c takeown /f "%1" && icacls "%1" /grant administrators:F'}
      # registry_value {'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore\\shell\\Windows.takeownership.files\\command\\IsolatedCommand': type => string, data => 'cmd.exe /c takeown /f "%1" && icacls "%1" /grant administrators:F'}

      # registry_key   {'HKCR\\*\\shell\\manage_menu': ensure => present}
      # registry_value {'HKCR\\*\\shell\\manage_menu\\SubCommands': type => string, data => 'Windows.takeownership.files'}
      # registry_value {'HKCR\\*\\shell\\manage_menu\\': type => string, data => 'Manage'}
      # registry_value {'HKCR\\*\\shell\\manage_menu\\icon': type => string, data => '%SystemRoot%\\System32\\shell32.dll,-137'}

      # registry_key   {'HKCR\\Directory\\shell\\manage_menu': ensure => present}
      # registry_value {'HKCR\\Directory\\shell\\manage_menu\\SubCommands': type => string, data => 'Windows.takeownership.directories'}
      # registry_value {'HKCR\\Directory\\shell\\manage_menu\\': type => string, data => 'Manage'}
      # registry_value {'HKCR\\Directory\\shell\\manage_menu\\icon': type => string, data => '%SystemRoot%\\System32\\shell32.dll,-137'}
      # registry_key   {'HKCR\\Directory\\Background\\shell\\manage_menu': ensure => present}
      # registry_value {'HKCR\\Directory\\Background\\shell\\manage_menu\\SubCommands': type => string, data => 'Windows.takeownership.directories'}
      # registry_value {'HKCR\\Directory\\Background\\shell\\manage_menu\\': type => string, data => 'Manage'}
      # registry_value {'HKCR\\Directory\\Background\\shell\\manage_menu\\icon': type => string, data => '%SystemRoot%\\System32\\shell32.dll,-137'}


      #enable checkboxes
      registry_value { "${hkcu}\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\AutoCheckSelect":
        ensure => present, type => dword, data => 0x00000001 }

      # add quick merge to context menu of reg-files
      registry_key   { 'HKCR\\regfile\\shell\\quickmerge\\command': ensure => present }
      registry_value { 'HKCR\\regfile\\shell\\quickmerge\\': ensure => present, type => string, data => 'Zusammenführen (Ohne Bestätigung)' }
      registry_value { 'HKCR\\regfile\\shell\\quickmerge\\Extended': ensure => absent, type => string}
      registry_value { 'HKCR\\regfile\\shell\\quickmerge\\NeverDefault': ensure => present, type => string }
      registry_value { 'HKCR\\regfile\\shell\\quickmerge\\command\\': ensure => present, type => string, data => 'regedit.exe /s "%1"' }

      # add 'Restart Explorer' to context menu of desktop
      registry_key   { 'HKCR\\DesktopBackground\\Shell\\Restart Explorer\\command': ensure => present }
      registry_value { 'HKCR\\DesktopBackground\\Shell\\Restart Explorer\\': ensure => present, type => string, data => 'Restart Explorer' }
      registry_value { 'HKCR\\DesktopBackground\\Shell\\Restart Explorer\\MUIVerb': ensure => present, type => string, data => 'Restart Explorer' }
      registry_value { 'HKCR\\DesktopBackground\\Shell\\Restart Explorer\\icon': ensure => present, type => string, data => 'explorer.exe' }
      registry_value { 'HKCR\\DesktopBackground\\Shell\\Restart Explorer\\command\\': ensure => present, type => string, data => 'TSKILL EXPLORER' }
    }

    if $is_my_user {
      # keyboard: remap capslock to shift
      registry_value { 'HKLM\\SYSTEM\\CurrentControlSet\\Control\\Keyboard Layout\\Scancode Map':
        ensure => present, type => binary, data => '00 00 00 00 00 00 00 00 02 00 00 00 2a 00 3a 00 00 00 00 00' }

      # Hide_Message_-_“Es_konnten_nicht_alle_Netzlaufwerke_wiederhergestellt_werden”
      registry_value { 'HKLM\\SYSTEM\\CurrentControlSet\\Control\\NetworkProvider\\RestoreConnection': 
        ensure => present, type => dword, data => '0x00000000' }

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

     }

    ###########################################################################
    ########## This PC tweaks #################################################
    ###########################################################################


    package { 'taskbar-winconfig':
      ensure          => present,
      install_options => ['--params', '"\'/LOCKED:yes', '/COMBINED:yes', '/PEOPLE:no', '/TASKVIEW:no', '/STORE:no', '/CORTANA:no\'"'],
    }

    $regkey_hklm_sw_x86 = 'HKLM\\SOFTWARE'
    $regkey_hklm_sw_x64 = 'HKLM\\SOFTWARE\\Wow6432Node'
    $regsubkey_mycomputer_ns = '\\Microsoft\\Windows\\CurrentVersion\\Explorer\\MyComputer\\NameSpace'
    $regsubkey_mycomputer_ns_x86 = "${regkey_hklm_sw_x86}${$regsubkey_mycomputer_ns}"
    $regsubkey_mycomputer_ns_x64 = "${regkey_hklm_sw_x64}${$regsubkey_mycomputer_ns}"

    if $is_my_user {
      # remove folders from desktop
      # https://chocolatey.org/packages/desktopicons-winconfig
      package { 'desktopicons-winconfig':
        ensure          => present,
        install_options => ['--params', '"/AllIcons:NO"'],
      }

      # Windows Explorer start to This PC
      registry_value {
        "${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\LaunchTo":
        type => dword, data => 0x00000001 }

      # how to hide element in 'This PC': http://www.thewindowsclub.com/remove-the-folders-from-this-pc-windows-10
      $regkey_folder_desc = 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FolderDescriptions'
      registry_value { [
          "${regkey_folder_desc}\\{f42ee2d3-909f-4907-8871-4c22fc0bf756}\\PropertyBag\\ThisPCPolicy", # Documents
          "${regkey_folder_desc}\\{0ddd015d-b06c-45d5-8c4c-f59713854639}\\PropertyBag\\ThisPCPolicy", # Pictures
          "${regkey_folder_desc}\\{35286a68-3c57-41a1-bbb1-0eae73d76c95}\\PropertyBag\\ThisPCPolicy", # Videos
        ]: ensure => present, type => string, data => 'Hide' }

      # remove '3D objects'
      registry_key { [
          "${regsubkey_mycomputer_ns_x86}\\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}",
          "${regsubkey_mycomputer_ns_x64}\\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
        ]: ensure => absent }
    }

    # ensure elements at 'This PC'
    registry_key { [
        "${regsubkey_mycomputer_ns_x86}\\{645FF040-5081-101B-9F08-00AA002F954E}", # ensure 'Recycling Bin' x86
        "${regsubkey_mycomputer_ns_x64}\\{645FF040-5081-101B-9F08-00AA002F954E}", # ensure 'Recycling Bin' x64
        "${regsubkey_mycomputer_ns_x86}\\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}", # ensure 'Desktop' x86
        "${regsubkey_mycomputer_ns_x64}\\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}", # ensure 'Desktop' x64
        "${regsubkey_mycomputer_ns_x86}\\{374DE290-123F-4565-9164-39C4925E467B}", # ensure 'Downloads' x86
        "${regsubkey_mycomputer_ns_x64}\\{374DE290-123F-4565-9164-39C4925E467B}", # ensure 'Downloads' x64
        "${regsubkey_mycomputer_ns_x86}\\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}", # ensure 'Music' x86
        "${regsubkey_mycomputer_ns_x64}\\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}", # ensure 'Music' x64
      ]: ensure => present }


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
    ########## Regedit tweaks ###########################################
    ###########################################################################
    if $is_my_user {
      registry_key {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites": ensure => present}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\App Paths": type => string, data => 'Computer\\HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\App Paths'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\AutoStart(System)": type => string, data => 'Computer\\HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\AutoStart(User)": type => string, data => 'Computer\\HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\Devices - AutorunHandlers": type => string, data => 'Computer\\HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\AutoplayHandlers\\Handlers'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\Devices - FormatMap": type => string, data => 'Computer\\HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows Portable Devices\\FormatMap'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\Environmental Vars (System)": type => string, data => 'Computer\\HKEY_LOCAL_MACHINE\\SYSTEM\\ControlSet001\\Control\\Session Manager\\Environment'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\Environmental Vars (User)": type => string, data => 'Computer\\HKEY_CURRENT_USER\\Environment'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\Explorer - My Computer: Additional Folders": type => string, data => 'Computer\\HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\MyComputer\\NameSpace'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\FileExts - All": type => string, data => 'Computer\\HKEY_CLASSES_ROOT\\AllFilesystemObjects'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\FileExts - Applications": type => string, data => 'Computer\\HKEY_CLASSES_ROOT\\Applications'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\FileExts - Unknown": type => string, data => 'Computer\\HKEY_CLASSES_ROOT\\Unknown'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\FileExts - MIME Types": type => string, data => 'Computer\\HKEY_CLASSES_ROOT\\MIME\\Database\\Content Type'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\FileExts - Open with": type => string, data => 'Computer\\HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FileExts'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\FileExts - PerceivedType": type => string, data => 'Computer\\HKEY_CLASSES_ROOT\\SystemFileAssociations'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\FileExts - Links": type => string, data => 'Computer\\HKEY_CLASSES_ROOT\\CLSID\\{00021401-0000-0000-C000-000000000046}'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\Firewall Rules": type => string, data => 'Computer\\HKEY_LOCAL_MACHINE\\SYSTEM\\ControlSet001\\services\\SharedAccess\\Parameters\\FirewallPolicy\\FirewallRules'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\MUICache": type => string, data => 'Computer\\HKEY_CURRENT_USER\\Software\\Classes\\Local Settings\\MuiCache'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\Network Adapters": type => string, data => 'Computer\\HKEY_CLASSES_ROOT\\CLSID\\{7007ACC7-3202-11D1-AAD2-00805FC1270E}'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\Services": type => string, data => 'Computer\\HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\Shell - Browser Helper Objects": type => string, data => 'Computer\\HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Browser Helper Objects'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\Shell - CommandStore (System)": type => string, data => 'Computer\\HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\Shell - DriveIcons": type => string, data => 'Computer\\HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\DriveIcons'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\Shell - Folders (System)": type => string, data => 'Computer\\HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\Shell - Folders (User)": type => string, data => 'Computer\\HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\Shell - Icons": type => string, data => 'Computer\\HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Icons'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\Shell - OverlayIcons(-ID)": type => string, data => 'Computer\\HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\ShellIconOverlayIdentifiers'}
      registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites\\System Control - Members": type => string, data => 'Computer\\HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Control Panel\\Extended Properties\\{305CA226-D286-468e-B848-2B2E8E697B74} 2'}
    }

    ###############################################################################
                                    # REGISTER / UNREGISTER  DLL & OCX FILE #	   #
    ###############################################################################
    #http://www.eightforums.com/tutorials/40512-register-unregister-context-menu-dll-ocx-files.html
    if $is_dev_pc {
      registry_key   { [
          'HKEY_CLASSES_ROOT\\dllfile\\shell\\Register\\command',
          'HKEY_CLASSES_ROOT\\dllfile\\shell\\Unregister\\command',
          'HKEY_CLASSES_ROOT\\ocxfile\\shell\\Register\\command',
          'HKEY_CLASSES_ROOT\\ocxfile\\shell\\Unregister\\command',
        ]: ensure => present }
      registry_value   { [
          'HKEY_CLASSES_ROOT\\dllfile\\shell\\Register\\command',
          'HKEY_CLASSES_ROOT\\ocxfile\\shell\\Register\\command',
        ]: type => string, data => 'regsvr32.exe "%L"' }
      registry_value   { [
          'HKEY_CLASSES_ROOT\\dllfile\\shell\\Unregister\\command',
          'HKEY_CLASSES_ROOT\\ocxfile\\shell\\Unregister\\command',
        ]: type => string, data => 'regsvr32.exe /u %L' }
    }
  }
}
