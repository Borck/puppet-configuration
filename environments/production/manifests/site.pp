define reg_ensure_file_ext(String $display_name, String $icon) {
  registry_key   { "HKCR\\${name}file": ensure => present }
  registry_value { "HKCR\\${name}file\\": data => $display_name }
  registry_key   { "HKCR\\${name}file\\defaulticon": ensure => present }
  registry_value { "HKCR\\${name}file\\defaulticon\\": data => $icon }
  registry_key   { "HKCR\\${name}file\\shell": ensure => present }
  registry_key   { "HKCR\\.${name}": ensure => present }
  registry_value { "HKCR\\.${name}\\": data => "${name}file" }
}

define reg_ensure_file_ext_value(String $value) {
  registry_value { "HKCR\\.${name}": data => $value }
}

define reg_ensure_archive_ext(String $icondirectory) {
  reg_ensure_file_ext { $name: display_name => "${name} Archive", icon => "${icondirectory}\\${name}.ico" }
  registry_key   { "HKCR\\${name}file\\shell\\open\\command": ensure => present }
  registry_value { "HKCR\\${name}file\\shell\\": data => 'open' }
  registry_value { "HKCR\\${name}file\\shell\\open\\command\\": data => '"C:\\Program Files\\7-Zip\\7zFM.exe" "%1"' }
  registry_value { "HKCR\\${name}file\\shell\\open\\Icon": data => '"C:\\Program Files\\7-Zip\\7zFM.exe"' }
  registry_value { "HKCR\\.${name}\\PerceivedType": data => 'compressed' }
}

class setup_win {
  # New modules and packages can be found here
  # https://forge.puppet.com/
  # https://chocolatey.org/


  ###########################################################################
  ########## TODO ###########################################################
  ###########################################################################
  # https://librarian-puppet.com/

  # https://forge.puppet.com/puppetlabs/scheduled_task
  # https://github.com/chocolatey-archive/chocolatey
  # https://chocolatey.org/packages/choco-upgrade-all-at
  # https://stackoverflow.com/questions/24579193/how-do-i-automatically-keep-all-locally-installed-chocolatey-packages-up-to-date

  # https://chocolatey.org/packages/launchy
  # https://chocolatey.org/packages/dropit
  # https://chocolatey.org/packages/exiftool
  # https://chocolatey.org/packages/sharemouse

  # https://github.com/puppetlabs/puppetlabs-windows

  ###########################################################################
  ########## Configuration ##################################################
  ###########################################################################

  $username = $identity['user']
  $hkcu = "HKU\\${identity_win['sid']}"
  $localappdata = $identity_win['localappdata']

  $is_my_pc   = 'borck' in downcase($hostname)
  $is_at_pc   = $hostname =~ /^AT\d+$/
  $is_dev_pc  = $is_my_pc or $is_at_pc
  $is_my_user = '\\borck' in downcase($username)

  # TODO extract this list programmatically by evaluating package ensurances
  $packages_do_not_upgrade_by_scheduled_task = [
    'office365proplus',
    'firefox',

    'ghostscript',
    'miktex',
    'texstudio',
    'jabref',

    'jdk8',
    'eclipse',
    'tortoisegit',

    'visualstudio2017enterprise',
    'visualstudio2017-workload-data',
    'visualstudio2017-workload-manageddesktop',
    'visualstudio2017-workload-nativecrossplat',
    'visualstudio2017-workload-nativedesktop',
    'visualstudio2017-workload-netcoretools',
    #'visualstudio2017-workload-universal',
    'visualstudio2017-workload-vctools',
    'visualstudio2017-workload-visualstudioextension',

    'unity',
    'unity-standard-assets'
  ]



  ###########################################################################
  ########## Script configuration ###########################################
  ###########################################################################

  # include chocolatey as default package provider
  include chocolatey
  Package { provider => chocolatey }



  ###########################################################################
  ########## Drivers/Device Software ########################################
  ###########################################################################

  package { 'sdio': ensure => present } # Snappy Driver Installer Origin (open source)
  # package { 'driverbooster': ensure => latest } # checksum error

  if $is_my_pc {
    package { 'logitech-options': ensure => latest } # Logitech Options software lets you customize your device settings
    registry_value {'HKLM\\SOFTWARE\\Logitech\\LogiOptions\\Analytics\\Enabled': data => '0'}
    xml_fragment { 'logitech-options_disable_non_silent_update_wizard':
      ensure  => 'present',
      path    => 'C:/ProgramData/Logishrd/LogiOptions/Software/Current/options.xml',
      xpath   => "useroptions/useroption[@name='automaticCheckForUpdates']",
      content => { attributes => { 'value' => '0' } }
    }
  }


  ###########################################################################
  ########## Office #########################################################
  ###########################################################################
  if $is_my_pc {
    package { 'office365proplus': ensure => present }
  }
  package { 'firefox': ensure => present } #firefox have a very silent update mechanism
  package { 'EdgeDeflector': ensure => latest } #redirects URIs to the default browser (caution: menu popup)


  #class {'sevenzip': package_ensure => 'latest', package_name => ['7zip'], prerelease => false }
  package { '7zip': ensure => latest }

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
  package { 'junction-link-magic': ensure => latest }
  package { 'bulkrenameutility': ensure => latest }
  registry_key { [
      'HKEY_CLASSES_ROOT\\*\\shellex\\ContextMenuHandlers\\BRUMenuHandler',
      'HKEY_CLASSES_ROOT\\Directory\\shellex\\ContextMenuHandlers\\BRUMenuHandler',
      'HKEY_CLASSES_ROOT\\Drive\\shellex\\ContextMenuHandlers\\BRUMenuHandler',
    ] : ensure => absent, require => Package['bulkrenameutility'] }
  #registry_value {"HKEY_CLASSES_ROOT\\Directory\\shellex\\ContextMenuHandlers\\BRUMenuHandler\\": \\ data => '{5D924130-4CB1-11DB-B0DE-0800200C9A66}'}


  ###########################################################################
  ########## Media tools/tweaks #############################################
  ###########################################################################

  package { 'vlc': ensure => latest }
  if $is_my_user {
    registry_value { [
        'HKCR\\Directory\\shell\\AddToPlaylistVLC\\LegacyDisable',
        'HKCR\\Directory\\shell\\PlayWithVLC\\LegacyDisable'
      ]: ensure => present, data => '', require => Package['vlc'] }
  }

  package { 'sketchup': ensure => latest }  # sketchup 2017, last free version

  package { 'caesium.install': ensure => latest }
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
      ]: ensure => present, data => '' }
    registry_key { 'HKCR\\SystemFileAssociations\\Directory.Audio\\shellex\\ContextMenuHandlers\\PlayTo': ensure => absent }
    #registry_value { 'HKCR\\SystemFileAssociations\\Directory.Audio\\shellex\\ContextMenuHandlers\\PlayTo\\': 
      #ensure => absent, data => '{7AD84985-87B4-4a16-BE58-8B72A5B390F7}' }
  }

  ###########################################################################
  ########## SVG/Inkscape ###################################################
  ###########################################################################
  package { 'inkscape': ensure => latest }
  $inkscape = "C:\\Program Files\\inkscape\\inkscape.exe"
  registry_key   {'HKCR\\Applications\\inkscape.exe\\shell\\open\\command': ensure => present}
  registry_value {'HKCR\\Applications\\inkscape.exe\\shell\\open\\command\\': data => "\"${inkscape}\", \"%1\""}
  registry_value {'HKCR\\Applications\\inkscape.exe\\shell\\open\\icon': data => "\"${inkscape}\", 0"}

  registry_key {'HKCR\\Applications\\inkscape.exe\\shell\\convertmenu': ensure => present}
  registry_value {'HKCR\\Applications\\inkscape.exe\\shell\\convertmenu\\ExtendedSubCommandsKey': data => 'Applications\\inkscape.exe\\ContextMenus\\converters'}
  registry_value {'HKCR\\Applications\\inkscape.exe\\shell\\convertmenu\\': data => 'Convert'}

  registry_key {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPng\\command': ensure => present}
  registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPng\\icon': data => "\"${inkscape}\", 0"}
  registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPng\\': data => 'Convert to PNG'}
  registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPng\\command\\': data => "\"${inkscape}\" -z \"%1\" -e \"%1.png\""}

  registry_key {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPs\\command': ensure => present}
  registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPs\\icon': data => "\"${inkscape}\", 0"}
  registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPs\\': data => 'Convert to PS'}
  registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPs\\command\\': data => "\"${inkscape}\" -z \"%1\" -P \"%1.ps\""}

  registry_key {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToEps\\command': ensure => present}
  registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToEps\\icon': data => "\"${inkscape}\", 0"}
  registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToEps\\': data => 'Convert to EPS'}
  registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToEps\\command\\': data => "\"${inkscape}\" -z \"%1\" -E \"%1.eps\""}

  registry_key {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPdf\\command': ensure => present}
  registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPdf\\icon': data => "\"${inkscape}\", 0"}
  registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPdf\\': data => 'Convert to PDF'}
  registry_value {'HKCR\\Applications\\inkscape.exe\\ContextMenus\\converters\\Shell\\ConvertToPdf\\command\\': data => "\"${inkscape}\" -z \"%1\" -A \"%1.pdf\""}



  ###########################################################################
  ########## Text tweaks ####################################################
  ###########################################################################

  $default_text_editor = 'C:\\Program Files\\Microsoft VS Code\\code.exe'
  #$default_text_editor = '%SystemRoot%\system32\NOTEPAD.EXE'

  # change *.txt file association
  registry_key   {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FileExts\\.txt\\UserChoice": ensure => present}
  registry_value {
    "${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FileExts\\.txt\\UserChoice\\ProgId": data => 'Applications\\code.exe';
    "${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FileExts\\.txt\\UserChoice\\Hash":   data => 'hK1YV2FCtgs=';
  }

  $notepad_replace_helperdir = 'C:\\ProgramData\\NotepadReplacer'
  $notepad_replace_helperlink = "${notepad_replace_helperdir}\\notepad.exe"
  # preferred symlink syntax
  file { $notepad_replace_helperdir: ensure => 'directory', }
  file { $notepad_replace_helperlink: ensure => 'link', target => $default_text_editor }

  package { 'notepadreplacer':
    ensure          => present,
    install_options => ['-installarguments', "\"/notepad=${notepad_replace_helperlink}", '/verysilent"'],
  }

  registry_value {'HKCR\\SystemFileAssociations\\text\\shell\\open\\icon': data => $notepad_replace_helperlink}
  registry_value {'HKCR\\SystemFileAssociations\\text\\shell\\edit\\LegacyDisable': data => ''}

  #comment code, because of changed 'Open With' setting above for *.txt files
  #registry_value {'HKCR\\txtfile\\shell\\open\\icon': data => $notepad_replace_helperlink}
  #registry_value {'HKCR\\txtfile\\shell\\print\\LegacyDisable': data => ''}
  #registry_value {'HKCR\\txtfile\\shell\\printto\\LegacyDisable': data => ''}




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
      ]: ensure => present, require => Package['git']
    }
    registry_value { [
      'HKCR\\Directory\\shell\\git_gui\\LegacyDisable',
      'HKCR\\Directory\\shell\\git_shell\\LegacyDisable',
      'HKCR\\Directory\\Background\\shell\\git_gui\\LegacyDisable',
      'HKCR\\Directory\\Background\\shell\\git_shell\\LegacyDisable',
      ]: ensure => present, data => '', require => Package['git']
    }

    # version control
    package { 
      'tortoisegit': ensure => present; #'tortoisegit': ensure => latest is causing errors
      'tortoisesvn': ensure => latest;
      'sourcetree': ensure => present;
    }

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
    package { 'resharper-ultimate-all': ensure => latest }
    #package { ['resharper', 'dotpeek', 'dotcover', 'dottrace', 'dotmemory']: ensure => present }

    # spy/browse the visual tree of a running WPF application ... and change properties
    package { 'snoop': ensure => latest }

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
  # registry_value {"HKEY_CLASSES_ROOT\\Directory\\shell\\AnyCode\\LegacyDisable": data => ''}
  # registry_value {"HKEY_CLASSES_ROOT\\Directory\\Background\\shell\\AnyCode\\LegacyDisable": data => ''}


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

  if $is_my_pc {
    package { 'winaero-tweaker': ensure => latest }
  }

  package { ['curl', 'wget']: ensure => latest }

  if $is_dev_pc {
    
    # network tools
    package { 
      'putty': ensure => latest;
      'winscp': ensure => latest;
      'wireshark': ensure => latest;
      'CloseTheDoor': ensure => latest; # close tcp/udp ports
    }

    # image tools
    package {
      'etcher': ensure => latest; # image to usb drive or sd card
      'rufus': ensure => latest; # format/create bootable USB flash drives
      #'win32diskimager': ensure => present;
    }

    # system tools
    package {
      'bluescreenview': ensure => latest;
      'regfromapp': ensure => latest;
      'Sysinternals': ensure => latest;
    }
  }

  ###########################################################################
  ########## File Explorer Tweaks ###########################################
  ###########################################################################

  #TODO install for all users instead of only current user
  package { 'quicklook': ensure => latest }
  registry_value {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Run\\QuickLook":
    data => "\"${localappdata}\\Programs\\QuickLook\\QuickLook.exe\" /autorun"}


  if $is_dev_pc {
    # Add 'Copy Path' to shift context menu
    # Tutorial: https://www.tenforums.com/tutorials/73649-copy-path-add-context-menu-windows-10-a.html
    registry_key   { 'HKCR\\AllFilesystemObjects\\shellex\\ContextMenuHandlers\\CopyAsPathMenu': ensure => present }
    registry_value { 'HKCR\\AllFilesystemObjects\\shellex\\ContextMenuHandlers\\CopyAsPathMenu\\':
      data => '{f3d06e7c-1e45-4a26-847e-f9fcdee59be0}' }


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
      ]: data => 'imageres.dll,-5323';
      [
        'HKCR\\Directory\\Background\\shell\\Terminals\\SubCommands',
        'HKCR\\Directory\\shell\\Terminals\\SubCommands',
        'HKCR\\Drive\\Background\\shell\\Terminals\\SubCommands',
        'HKCR\\Drive\\shell\\Terminals\\SubCommands'
      ]: data => 'Windows.MultiVerb.cmd;Windows.MultiVerb.cmdPromptAsAdministrator;|;Windows.MultiVerb.Powershell;Windows.MultiVerb.PowershellAsAdmin'  
    }


    # for powershell scripts (*.ps1): add 'Run as administrator' to context menu
    registry_key   { 'HKCR\\Microsoft.PowerShellScript.1\\Shell\\runas\\command':      ensure => present }
    registry_value { 
      'HKCR\\Microsoft.PowerShellScript.1\\Shell\\runas\\HasLUAShield': data => '';
      'HKCR\\Microsoft.PowerShellScript.1\\Shell\\runas\\MUIVerb':      data => '@shell32.dll,-37448';
      'HKCR\\Microsoft.PowerShellScript.1\\Shell\\runas\\command\\': 
        data   => 'powershell.exe "-Command" "if((Get-ExecutionPolicy ) -ne \'AllSigned\') { Set-ExecutionPolicy -Scope Process Bypass }; & \'%1\'"';
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
  package { 'svg-explorer-extension': ensure => latest }
  reg_ensure_file_ext { 'svg' : display_name => 'Scalable Vector Graphics', icon => "${icons}\\svgfile.ico" }
  reg_ensure_file_ext_value { 
    'svg\\Content Type'  : value => 'image/svg+xml';
    'svg\\PerceivedType' : value => 'image';
  }


  if $is_my_user {
    # recycle bin
    # https://www.tenforums.com/tutorials/12479-change-recycle-bin-icon-windows-10-a.html#option1
    # if icons not applied, maybe 'Remove Recycling Bin from Desktop' from GPO have to be disabled,
    # NOTE: the recycling bin can also be remove on 'Configure Desktop Icons' window, [WIN]+[R] and type:
    #       rundll32.EXE shell32.dll,Control_RunDLL desk.cpl,,0
    # NOTE: https://www.windows-faq.de/2017/12/27/papierkorb-symbol-nicht-auf-dem-desktop-anzeigen/ 

    $recyclebin_reg = "${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CLSID\\{645FF040-5081-101B-9F08-00AA002F954E}"
    registry_value { [
        "${recyclebin_reg}\\DefaultIcon\\",
        "${recyclebin_reg}\\DefaultIcon\\full"
      ]:                                       data => "${icons}\\recycle-bin-full.ico,0";
      "${recyclebin_reg}\\DefaultIcon\\empty": data => "${icons}\\recycle-bin-empty.ico,0";
    }

    registry_key   { "${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\NonEnum": ensure => present }
    # set to zero (disabled), because of issues with customized icons
    registry_value { "${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\NonEnum\\{645FF040-5081-101B-9F08-00AA002F954E}":
      type => dword, data => 0x00000000 }
  }

  if $is_dev_pc {
    #take ownership context entry
    # registry_key   {'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore\\shell\\Windows.takeownership.directories\\command': ensure => present}
    # registry_value {'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore\\shell\\Windows.takeownership.directories\\': data => 'Take Ownership'}
    # registry_value {'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore\\shell\\Windows.takeownership.directories\\NoWorkingDirectory': data => ''}
    # registry_value {'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore\\shell\\Windows.takeownership.directories\\command\\': data => 'cmd.exe /c takeown /f "%1" /r /d y && icacls "%1" /grant administrators:F /t'}
    # registry_value {'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore\\shell\\Windows.takeownership.directories\\command\\IsolatedCommand': data => 'cmd.exe /c takeown /f "%1" /r /d y && icacls "%1" /grant administrators:F /t'}

    # registry_key   {'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore\\shell\\Windows.takeownership.files\\command': ensure => present}
    # registry_value {'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore\\shell\\Windows.takeownership.files\\': data => 'Take Ownership'}
    # registry_value {'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore\\shell\\Windows.takeownership.files\\NoWorkingDirectory': data => ''}
    # registry_value {'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore\\shell\\Windows.takeownership.files\\command\\': data => 'cmd.exe /c takeown /f "%1" && icacls "%1" /grant administrators:F'}
    # registry_value {'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore\\shell\\Windows.takeownership.files\\command\\IsolatedCommand': data => 'cmd.exe /c takeown /f "%1" && icacls "%1" /grant administrators:F'}

    # registry_key   {'HKCR\\*\\shell\\manage_menu': ensure => present}
    # registry_value {'HKCR\\*\\shell\\manage_menu\\SubCommands': data => 'Windows.takeownership.files'}
    # registry_value {'HKCR\\*\\shell\\manage_menu\\': data => 'Manage'}
    # registry_value {'HKCR\\*\\shell\\manage_menu\\icon': data => '%SystemRoot%\\System32\\shell32.dll,-137'}

    # registry_key   {'HKCR\\Directory\\shell\\manage_menu': ensure => present}
    # registry_value {'HKCR\\Directory\\shell\\manage_menu\\SubCommands': data => 'Windows.takeownership.directories'}
    # registry_value {'HKCR\\Directory\\shell\\manage_menu\\': data => 'Manage'}
    # registry_value {'HKCR\\Directory\\shell\\manage_menu\\icon': data => '%SystemRoot%\\System32\\shell32.dll,-137'}
    # registry_key   {'HKCR\\Directory\\Background\\shell\\manage_menu': ensure => present}
    # registry_value {'HKCR\\Directory\\Background\\shell\\manage_menu\\SubCommands': data => 'Windows.takeownership.directories'}
    # registry_value {'HKCR\\Directory\\Background\\shell\\manage_menu\\': data => 'Manage'}
    # registry_value {'HKCR\\Directory\\Background\\shell\\manage_menu\\icon': data => '%SystemRoot%\\System32\\shell32.dll,-137'}


    #enable checkboxes
    registry_value { "${hkcu}\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\AutoCheckSelect":
      ensure => present, type => dword, data => 0x00000001 }

    # add quick merge to context menu of reg-files
    registry_key   { 'HKCR\\regfile\\shell\\quickmerge\\command': ensure => present }
    registry_value { 
      'HKCR\\regfile\\shell\\quickmerge\\':             data   => 'Quick Merge (no confirm)';
      'HKCR\\regfile\\shell\\quickmerge\\Extended':     ensure => absent;
      'HKCR\\regfile\\shell\\quickmerge\\NeverDefault': data   => '';
      'HKCR\\regfile\\shell\\quickmerge\\command\\':    data   => 'regedit.exe /s "%1"'
    }

    # add 'Restart Explorer' to context menu of desktop
    registry_key   { 'HKCR\\DesktopBackground\\Shell\\Restart Explorer\\command': ensure => present }
    registry_value { [
        'HKCR\\DesktopBackground\\Shell\\Restart Explorer\\',
        'HKCR\\DesktopBackground\\Shell\\Restart Explorer\\MUIVerb'
      ]: ensure => present, data => 'Restart Explorer';
      'HKCR\\DesktopBackground\\Shell\\Restart Explorer\\icon': ensure => present, data => 'explorer.exe';
      'HKCR\\DesktopBackground\\Shell\\Restart Explorer\\command\\': ensure => present, data => 'TSKILL EXPLORER';
    }
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
    # registry_value { 'HKCR\\Folder\\ShellEx\\ContextMenuHandlers\\Library Location\\': ensure => present, data => '{3dad6c5d-2167-4cae-9914-f99e41c12cfa}' }

    # remove 'Scan with Windows Defender' from context menu
    registry_key   { [
      'HKCR\\*\\shellex\\ContextMenuHandlers\\EPP',
      'HKCR\\Directory\\shellex\\ContextMenuHandlers\\EPP',
      'HKCR\\Drive\\shellex\\ContextMenuHandlers\\EPP'

      # backup:
      # registry_value { 'HKCR\\*\\ShellEx\\ContextMenuHandlers\\EPP\\': ensure => present, data => '{09A47860-11B0-4DA5-AFA5-26D86198A780}' }
      # registry_value { 'HKCR\\Directory\\ShellEx\\ContextMenuHandlers\\EPP\\': ensure => present, data => '{09A47860-11B0-4DA5-AFA5-26D86198A780}' }
    ]: ensure => absent }


    # Disable AutoPlay for removable media drives for CurrentUser
    registry_value { 'HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer\\NoDriveTypeAutoRun':
      ensure => present, type => dword, data => 0x000000b5 }

    # Remove 'Shortcut' from new links
    # registry_value { 'HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\link': ensure => present, type => binary, data => '00 00 00 00' }
    # backup: data => '1e 00 00 00'
  }

  # REGISTER / UNREGISTER  DLL & OCX FILE
  #http://www.eightforums.com/tutorials/40512-register-unregister-context-menu-dll-ocx-files.html
  registry_key   { [
      'HKCR\\dllfile\\shell\\Register\\command',
      'HKCR\\dllfile\\shell\\Unregister\\command',
      'HKCR\\ocxfile\\shell\\Register\\command',
      'HKCR\\ocxfile\\shell\\Unregister\\command',
    ]: ensure => present }
  registry_value   {
    [
      'HKCR\\dllfile\\shell\\Register\\command',
      'HKCR\\ocxfile\\shell\\Register\\command',
    ]: data => 'regsvr32.exe "%L"';
    [
      'HKCR\\dllfile\\shell\\Unregister\\command',
      'HKCR\\ocxfile\\shell\\Unregister\\command',
    ]: data => 'regsvr32.exe /u %L';
  }


  ###########################################################################
  ########## This PC Tweaks #################################################
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
      ensure          => latest,
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
      ]: ensure => present, data => 'Hide' }

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
  ########## Regedit tweaks #################################################
  ###########################################################################
  if $is_my_user {
    $hkcu_regfav = "${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites"
    registry_key {"${hkcu_regfav}": ensure => present, purge_values => true }
    registry_value {
      "${hkcu_regfav}\\App Paths":   data => 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\App Paths';
      "${hkcu_regfav}\\Autorun (S)": data => 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run';
      "${hkcu_regfav}\\Autorun (U)": data => 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run';
      "${hkcu_regfav}\\EnvVars (S)": data => 'HKLM\\SYSTEM\\ControlSet001\\Control\\Session Manager\\Environment';
      "${hkcu_regfav}\\EnvVars (U)": data => 'HKCU\\Environment';
      "${hkcu_regfav}\\Files: All": data => 'HKCR\\AllFilesystemObjects';
      "${hkcu_regfav}\\Files: Apps": data => 'HKCR\\Applications';
      "${hkcu_regfav}\\Files: Unknown": data => 'HKCR\\Unknown';
      "${hkcu_regfav}\\Files: MIME Types": data => 'HKCR\\MIME\\Database\\Content Type';
      "${hkcu_regfav}\\Files: Open With": data => 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FileExts';
      "${hkcu_regfav}\\Files: PerceivedType": data => 'HKCR\\SystemFileAssociations';
      "${hkcu_regfav}\\Files: Links": data => 'HKCR\\CLSID\\{00021401-0000-0000-C000-000000000046}';
      "${hkcu_regfav}\\Firewall Rules": data => 'HKLM\\SYSTEM\\ControlSet001\\services\\SharedAccess\\Parameters\\FirewallPolicy\\FirewallRules';
      "${hkcu_regfav}\\MUICache": data => 'HKCU\\Software\\Classes\\Local Settings\\MuiCache';
      "${hkcu_regfav}\\Network Adapters": data => 'HKCR\\CLSID\\{7007ACC7-3202-11D1-AAD2-00805FC1270E}';
      "${hkcu_regfav}\\Reg: Favorites": data => 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites';
      "${hkcu_regfav}\\Services": data => 'HKLM\\SYSTEM\\CurrentControlSet\\Services';
      "${hkcu_regfav}\\Sh: Browser Helper Objects": data => 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Browser Helper Objects';
      "${hkcu_regfav}\\Sh: CommandStore (S)": data => 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore';
      "${hkcu_regfav}\\Sh: DriveIcons": data => 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\DriveIcons';
      "${hkcu_regfav}\\Sh: Folders (S)": data => 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders';
      "${hkcu_regfav}\\Sh: Folders (U)": data => 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders';
      "${hkcu_regfav}\\Sh: Icons": data => 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Icons';
      "${hkcu_regfav}\\Sh: OverlayIcons(-ID)": data => 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\ShellIconOverlayIdentifiers';
    }
  }

  ###########################################################################
  ########## Schedule/configure update tasks ################################
  ###########################################################################

  $pp_conf = "${sysenv['pp_confdir']}/puppet.conf"

  # display current value: puppet agent --configprint runinterval
  ini_setting { "pp_runinterval":
    ensure  => present, path => $pp_conf, section => 'agent', setting => 'runinterval', value   => '7d',
  }
  ini_setting { "pp_runruntimeout":
    ensure  => present, path => $pp_conf, section => 'agent', setting => 'runtimeout', value   => '12h',
  }

  $cup_all_path ='C:\\ProgramData\\chocolatey.upgradeall.puppet'
  $cup_script             = "${cup_all_path}\\upgrade.ps1"
  $cup_script_pre  = "${cup_all_path}\\preupgrade.ps1"
  $cup_script_post = "${cup_all_path}\\postupgrade.ps1"

  $cup_owner = 'Administrator'
  $cup_group = 'Administratoren' #TODO make this generic

  $cup_script_content = @("EOT"/)
    # do not change this script, the scheduled puppet task may overwrite this changes, instead use one of this files:
    # ${cup_script_pre}
    # ${cup_script_post}
    Set-Location \$PSScriptRoot
    
    \$excepted_packages = "${join($packages_do_not_upgrade_by_scheduled_task,',')}"
    
    . ${cup_script_pre}

    choco upgrade all -y --except=\$excepted_packages

    . ${cup_script_post}
    |-EOT

  file { $cup_all_path: ensure => 'directory', owner => $cup_owner, group => $cup_group }
  file { [$cup_script_pre, $cup_script_post]:
    ensure => 'file', owner => $cup_owner, group => $cup_group, replace => 'no', content => "" }
  file { $cup_script: ensure => 'file', owner => $cup_owner, group => $cup_group, replace => 'yes', content => $cup_script_content }



  scheduled_task { 'Chocolatey Upgrade All':
    enabled   => true,
    command   => "${::system32}\\WindowsPowerShell\\v1.0\\powershell.exe",
    arguments => "-File \"${cup_script}\"",
    user      => 'system',
    trigger   => [{
      schedule   => 'daily',
      start_time => '11:30'
    }],
  }
}


node default {
  if $::kernel != 'windows' {
    fail{'Only windows is supported':}
  }
  include setup_win
}

