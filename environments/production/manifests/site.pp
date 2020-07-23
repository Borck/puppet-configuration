class setup_win {
  notice('#######################################')
  notice('Running Puppet Setup Script For Windows')
  notice('#######################################')
  notice('')


  ######################################################################################################################
  ###################################### Documentation #################################################################
  ######################################################################################################################

  # language overview: https://puppet.com/docs/puppet/6.0/lang_visual_index.html
  # define resources:  https://puppet.com/docs/puppet/5.0/lang_defined_types.html

  # New modules and packages can be found here
  # https://forge.puppet.com/

  # include chocolatey as default package provider


  ####context menu #######
  # https://www.askvg.com/how-to-customize-rename-remove-or-hide-command-bar-buttons-in-windows-7-explorer/
  # https://blog.sverrirs.com/2014/05/creating-cascading-menu-items-in.html
  # https://stackoverflow.com/questions/39806367/add-a-separator-in-the-windows-explorer-context-menu-not-in-a-submenu

  ######################################################################################################################
  ###################################### TODO ##########################################################################
  ######################################################################################################################
  # package matrix
  # csv file which containes the packages to install under different users/groups/systems
  # groups: normal_users, advanced_users ,dev_users, etc.
  # TODO groups be join using a install script and are refered in the registry

  # announce scheduled software update x hours before, and all to skip it

  #   if !defined(Registry_key[$key]) {
  #     registry_key { $key: }
  #   }

  # add option to move user directory to d: drive
  # https://www.sevenforums.com/tutorials/87555-user-profile-change-default-location.html

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

  # relocate shell/library folders to new locations/drive/paritions
  # shell/library folders: COOKIES | SENDTO | DOCS | FAVS | PICS | MUSIC | VIDEO | TIF | DOWNLOAD | TEMPLATES
  #http://www.tweakhound.com/2013/10/22/tweaking-windows-8-1/5/
  #[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders]

  ######################################################################################################################
  ###################################### Main #################################################################
  ######################################################################################################################

  $username   = $::identity['user']
  $is_my_pc   = 'borck' in downcase($::hostname)
  $is_my_stationary_pc   = $is_my_pc and 'PC' in downcase($::hostname)
  $is_at_pc   = $::hostname =~ /^AT\d+$/
  $is_my_user = downcase($username) =~ /\\.*borck/
  #'\\borck' in downcase($username)
  $is_render_pc = $is_my_stationary_pc or $is_at_pc

  # $test = hiera('packages')
  # into($test)

  $profile = {
    office               => true,
    office_advanced      => $is_my_user,
    office_latex         => $is_my_pc or $is_at_pc,
    office_365proplus    => false,
    media                => $is_my_pc,
    administration       => $is_my_user or $is_my_pc,
    puppet               => true,
    puppet_admin         => $is_my_pc,
    browser_firefox      => $is_my_user,
    browser_chrome       => false,
    browser_opera        => false,
    dev_basics           => $is_my_user,
    dev_dotnet           => $is_my_user,
    dev_vs2017enterprise => false,
    dev_vs2017community  => false,
    dev_vs2019enterprise => $is_my_user,
    dev_vs2019community  => false,
    dev_java             => false,
    dev_python           => $is_my_user,
    dev_microcontroller  => $is_my_pc,
    dev3d_unity          => $is_render_pc,
    dev3d_blender        => $is_render_pc,
    dev3d_humanoid       => $is_render_pc,
    driver_tools         => $is_my_pc,
    driver_logitech_io   => $is_my_pc,
    workflow             => $is_my_user,
  }

  include icons

  include chocolatey
  Package { provider => chocolatey, ensure => present }

  notice("Apply profile:\n${profile}")
  notice('')

  #$packages_to_install=get_win_packages($profile)
# function get_win_packages(SetupProfile $profile) >> Hash[String, PackageSetup] {
  $package_defaults = $facts[resources_win_package_defaults]
  $packages = $facts[resources_win_packages]
              .map|$name, $setup|{ [$name, $package_defaults+$setup] }
              .convert_to(Hash)
  notice("Package defaults:\n${package_defaults}")
  notice("Packages:\n${packages}")
  notice('')
  #TODO merge with defaults

  $packages_to_install = $packages
  .filter|$name, $setup|{
    $setup_profile = $setup['profile']
    $setup['ensure'] != 'ignore_from_upgrade' and
    $setup_profile ? {
      String        => $profile[$setup_profile],
      Array[String] => $setup_profile.reduce(false) |Boolean $memo, String $pkg_profile| {
        $memo or ($profile[$pkg_profile] == true)
      }
    }
  }
# }


  $packages_names = join(($packages_to_install.map |$name,$setup| {$name}).sort,', ')
  notice("Apply packages:\n${packages_names}")

  class {'setup_packages': packages => $packages_to_install, profile => $profile}
  class {'setup_package_auto_upgrade_task': packages => $packages} # use all packages to prevent upgrade of side installations like unity
  #class {'packages':             profile => $profile }


  class { 'win_configure': profile => $profile }

  if $is_my_pc {
    class {'nas_mount':}
  }
}




########################################################################################################################
###################################### Package setup ###################################################################
########################################################################################################################

type PackageSetup = Struct[{
  profile => Variant[String,Array[String]],
  Optional[provider]             => String,
  Optional[install_options]      => Array[String],
  Optional[ensure]               => String,
  Optional[preprocess]           => String,
  Optional[postprocess]          => String,
  Optional[postprocessOnRefresh] => String,
}]



type SetupProfile = Struct[{
  Optional[office]               => Boolean,
  Optional[office_advanced]      => Boolean,
  Optional[office_latex]         => Boolean,
  Optional[office_365proplus]    => Boolean,
  Optional[media]                => Boolean,
  Optional[administration]       => Boolean,
  Optional[puppet]               => Boolean,
  Optional[puppet_admin]         => Boolean,
  Optional[browser_firefox]      => Boolean,
  Optional[browser_chrome]       => Boolean,
  Optional[browser_opera]        => Boolean,
  Optional[dev_basics]           => Boolean,
  Optional[dev_dotnet]           => Boolean,
  Optional[dev_vs2017enterprise] => Boolean,
  Optional[dev_vs2017community]  => Boolean,
  Optional[dev_vs2019enterprise] => Boolean,
  Optional[dev_vs2019community]  => Boolean,
  Optional[dev_java]             => Boolean,
  Optional[dev_python]           => Boolean,
  Optional[dev_microcontroller]  => Boolean,
  Optional[dev3d_unity]          => Boolean,
  Optional[dev3d_blender]        => Boolean,
  Optional[dev3d_humanoid]       => Boolean,
  Optional[driver_tools]         => Boolean,
  Optional[driver_logitech_io]   => Boolean,
  Optional[workflow]             => Boolean,
}]



class setup_packages( Hash[String, PackageSetup] $packages, SetupProfile $profile ) {
  $packages.each |String $name, PackageSetup $setup|{
    setup_package {$name: setup => $setup, profile => $profile}
  }
}



class setup_package_auto_upgrade_task(Hash[String, PackageSetup] $packages) {
  class {'package_upgrade_task':
      ignored_packages => $packages
        .filter |String $name, PackageSetup $setup| { $setup['ensure'] != 'latest' and $setup['ensure'] != undef }
        .map |$name, $setup| {$name}
    }
}



define setup_package(PackageSetup $setup, SetupProfile $profile){
  package{$name:
    ensure          => $setup['ensure']? { latest  => 'present', default => $setup['ensure'] },
    install_options => $setup['install_options'],
  }

  if $setup['preprocess'] {
    class { $setup['preprocess']: profile => $profile, before => Package[$name]}
  }
  if $setup['postprocess'] {
    class { $setup['postprocess']: profile => $profile, require => Package[$name]}
  }
  if $setup['postprocessOnRefresh'] {
    class { $setup['postprocessOnRefresh']: profile => $profile, subscribe => Package[$name]}
  }
}



# Customize Start screen tiles for desktop apps
# 
# Documentation:
# https://docs.microsoft.com/en-us/previous-versions/windows/apps/dn393983(v=win.10)?redirectedfrom=MSDN
#
#
# <VisualElements ShowNameOnSquare150x150Logo="on" Square150x150Logo="VisualElements\MediumIconUnity.png" Square70x70Logo="VisualElements\SmallIconUnity.png" ForegroundText="light" BackgroundColor="#0078D7" />
define ensure_exe_tile(
  String                                    $logo_small,
  String                                    $logo_medium,
  Optional[Enum['light', 'dark', 'absent']] $foreground_text  = 'light',
  Optional[Integer]                         $background_color = undef,
  String                                    $tile_subdir      = 'VisualElements'
  ){

  # matches files ($1: directory, $2: filename, $3: filename without extension, $4: extension)
  # TODO: does not match C:\atg.exe
  if $name =~ /^([a-zA-Z]:(?:\\(?![<>:"\/\\|?*])).*)\\(((?![<>:"\/\\|?*]).*)\.((?![<>:"\/\\|?*]).*))$/ {
    $exe_dir  = $1
    $exe_name_without_ext = $3

    # TODO ensure exe exists 

    $tiles = [ $logo_small, $logo_medium ]

    $visual_element_args = delete_undef_values({
      'Square70x70Logo'             => "${tile_subdir}/${logo_small}",
      'Square150x150Logo'           => "${tile_subdir}/${logo_medium}",
      'ShowNameOnSquare150x150Logo' => $foreground_text ? {'absent' => 'off', undef => undef, default => 'on'},
      'ForegroundText'              => $foreground_text ? {'absent' => 'light', default => $foreground_text},
      'BackgroundColor'             => $background_color ? {undef => '#000000', default => '#%06X' % $background_color},
      # https://stackoverflow.com/questions/84421/converting-an-integer-to-a-hexadecimal-string-in-ruby
    })
    $exe_tile_dir = "${$exe_dir}/${tile_subdir}"
    $class_exe_tile_dir = "tile directory ${exe_tile_dir}"
    file { $class_exe_tile_dir: ensure => directory, path => $exe_tile_dir }
    $tiles.filter| $tile | {$tile.is_a(String)}
          .unique
          .each|String $tile|{
            info("apply tile ${tile}")
            file { "tile ${name}:${tile}":
              ensure             => present,
              path               => "${exe_tile_dir}/${tile}",
              source             => "puppet:///modules/resources/tile/${tile}",
              source_permissions => ignore,
              require            => File[$class_exe_tile_dir],
              notify             => Refresh_links[$name]
            }
    }

    $manifest = "${exe_dir}/${exe_name_without_ext}.VisualElementsManifest.xml"

    file { $manifest:
      ensure  => present,
      replace => false,
      path    => $manifest,
      source  => 'puppet:///modules/resources/tile/_template.VisualElementsManifest.xml',
      notify  => Refresh_links[$name]
    }
    xml_fragment { "${manifest}/Application":
      ensure  => present,
      path    => $manifest,
      xpath   => '/Application',
      content => { attributes => { 'GeneratedByPuppet' => true }},
      notify  => Refresh_links[$name]
    }
    xml_fragment { "${manifest}/Application/VisualElements":
      ensure  => present,
      path    => $manifest,
      xpath   => '/Application/VisualElements',
      content => { attributes => $visual_element_args},
      notify  => Refresh_links[$name]
    }


    # TODO refresh lnk file using powershell
    # https://stackoverflow.com/questions/40738969/securely-passing-parameters-to-powershell-scripts-executed-with-puppet
    Refresh_links{$name:}
  } else {
    warning("Can not apply tiles to the application: ${name}")
  }
}



define refresh_links(String $targets = $name) {
  #TODO refresh only test
  #https://puppet.com/docs/puppet/5.5/types/exec.html
  $template = 'system_env/refresh_lnk_by_target.ps1.epp'
  exec {
    default:
      provider    => powershell,
      logoutput   => true,
      refreshonly => false,
    ;
    "refresh start menu links (user) for ${targets}"   : command => epp($template, { targets => $targets, user => true });
    "refresh start menu links (system) for ${targets}" : command => epp($template, { targets => $targets, user => false });
  }
}



########################################################################################################################
###################################### Package Post Processing #########################################################
########################################################################################################################


class pkgpost_mp3tag( SetupProfile $profile ) {
  if ($profile['workflow']) {
    registry_key {'HKCR\\Directory\\shellex\\ContextMenuHandlers\\Mp3tagShell': ensure  => absent }
  }
}


class pkgpost_bulkrenameutility( SetupProfile $profile ) {
  if ($profile['workflow']) {
    registry_key { [
        'HKCR\\*\\shellex\\ContextMenuHandlers\\BRUMenuHandler',
        'HKCR\\Directory\\shellex\\ContextMenuHandlers\\BRUMenuHandler',
        'HKCR\\Drive\\shellex\\ContextMenuHandlers\\BRUMenuHandler',
      ] : ensure => absent }
    #registry_value {"HKCR\\Directory\\shellex\\ContextMenuHandlers\\BRUMenuHandler\\": \\ data => '{5D924130-4CB1-11DB-B0DE-0800200C9A66}'}
  }
}


class pkgpost_vscode( SetupProfile $profile ) {
  $path = "${::windows_env['PROGRAMFILES']}\\Microsoft VS Code\\Code.exe"
  registry_value { 'HKCR\\Applications\\Code.exe\\shell\\open\\icon': data => "\"${path}\", 0" }

  if ($profile['workflow']) {
    class {'replace_notepad': path => $path }
  }
}



class pkgpost_vlc( SetupProfile $profile ) {
  if ($profile['workflow']) {
    registry_value { [
        'HKCR\\Directory\\shell\\AddToPlaylistVLC\\LegacyDisable',
        'HKCR\\Directory\\shell\\PlayWithVLC\\LegacyDisable'
      ]: data => ''
    }
  }
}


class pkgpost_git( SetupProfile $profile ) {
  if ($profile['workflow']) {
    registryx::shell_command { [
      'HKCR\\Directory\\shell\\git_gui',
      'HKCR\\Directory\\shell\\git_shell',
      'HKCR\\Directory\\Background\\shell\\git_gui',
      'HKCR\\Directory\\Background\\shell\\git_shell',
      ]: legacy_disable => ''
    }
  }
}


class pkgpost_logitech_options( SetupProfile $profile ) {
  registry_value { 'HKLM\\SOFTWARE\\Logitech\\LogiOptions\\Analytics\\Enabled': data => '0' }
  registry_value { 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\StartupApproved\\Run\\Logitech Download Assistant':
    type => binary, data => '03 00 00 00 C9 10 E8 40 38 8B D5 01'}
  registry_value { 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\StartupApproved\\Run\\LogiOptions':
    type => binary, data => '03 00 00 00 DC 31 B4 6B 3E 8B D5 01'}

  xml_fragment { 'logitech-options_disable_non_silent_update_wizard':
    ensure  => 'present',
    path    => "${::windows_env['PROGRAMDATA']}/Logishrd/LogiOptions/Software/Current/options.xml",
    xpath   => "useroptions/useroption[@name='automaticCheckForUpdates']",
    content => { attributes => { 'value' => '0' } },
  }
}


class pkgpost_quicklook( SetupProfile $profile ) {
  registry_value {"HKU\\${::identity_win['sid']}\\Software\\Microsoft\\Windows\\CurrentVersion\\Run\\QuickLook":
    data    => "\"${::windows_env['LOCALAPPDATA']}\\Programs\\QuickLook\\QuickLook.exe\" /autorun",
  }
}


class pkgpost_inkscape( SetupProfile $profile ) {
  package { 'svg-explorer-extension': require => Package['inkscape']}
  registryx::class { 'HKCR\\svgfile' :
    name_or_ref  => 'Scalable Vector Graphics (SVG)',
    default_icon => "${getparam(File['Icons.puppet'], 'path')}\\svgfile.ico",
    require      => File['Icons.puppet'],
  }
    ->
  registryx::class { 'HKCR\\.svg' :
    name_or_ref    => 'svgfile',
    content_type   => 'image/svg+xml',
    perceived_type => 'image',
  }

  if ($profile['workflow']) {
    $inkscape = "${::windows_env['PROGRAMFILES']}\\inkscape\\inkscape.exe"
    $inkscape_reg_convertermenu = 'Applications\\inkscape.exe\\ContextMenus\\converters'
    registryx::class { 'HKCR\\Applications\\inkscape.exe':
      shell   => {
        'open'        => {command => "\"${inkscape}\" \"%1\"", icon => "\"${inkscape}\", 0"},
        'convertmenu' => {name_or_ref => 'Convert', extended_sub_commands_key => $inkscape_reg_convertermenu}
      },
    }
      ->
    registryx::class { "HKCR\\${inkscape_reg_convertermenu}":
      shell   => {
        'ConvertToPng' => {name_or_ref => 'Convert to PNG', icon => "\"${inkscape}\", 0", command => "\"${inkscape}\" -z \"%1\" -e \"%1.png\""},
        'ConvertToPs'  => {name_or_ref => 'Convert to PS',  icon => "\"${inkscape}\", 0", command => "\"${inkscape}\" -z \"%1\" -P \"%1.ps\"" },
        'ConvertToEps' => {name_or_ref => 'Convert to EPS', icon => "\"${inkscape}\", 0", command => "\"${inkscape}\" -z \"%1\" -E \"%1.eps\""},
        'ConvertToPdf' => {name_or_ref => 'Convert to PDF', icon => "\"${inkscape}\", 0", command => "\"${inkscape}\" -z \"%1\" -A \"%1.pdf\""},
      },
    }
  }
}

class pkgpost_caesium( SetupProfile $profile ) {
  if ($profile['workflow']) {
    $startmenu_all = "${::windows_env['PROGRAMDATA']}\\Microsoft\\Windows\\Start Menu\\Programs"
    file { "${startmenu_all}\\Caesium\\Caesium.lnk": ensure  => absent, }
    file { "${startmenu_all}\\Caesium\\Caesium - Image Converter.lnk":
      ensure => present,
      source => "puppet:///modules/resources/lnk/Caesium_${::architecture}.lnk",
    }
  }
}

class pkgpost_sevenzip( SetupProfile $profile ) {
  $archive_types = ['001', '7z', 'bz2', 'gz', 'rar', 'tar']
  $archive_tool = "${::windows_env['PROGRAMFILES']}\\7-Zip\\7zFM.exe"
  $archive_icons = "${getparam(File['Icons.puppet'], 'path')}\\7_zip_filetype_theme___windows_10_by_masamunecyrus-d93yxyk"

  $archive_types.each |String $name| {
    $name_real = "${name}file"
    registryx::class { "HKCR\\${name_real}":
      name_or_ref  => "${upcase($name)}-Archive",
      default_icon => "${archive_icons}\\${name}.ico",
      shell        => { 'open' => {
                          command => "\"${archive_tool}\" \"%1\"",
                          icon    => "\"${archive_tool}\",0"
                        }
                      },
      require      => Class['icons'],
    }
    registryx::class { "HKCR\\.${name}":
      name_or_ref => $name_real,
      require     => Class['icons'],
    }
  }
}

class pkgpost_unity( SetupProfile $profile ) {
  ensure_exe_tile {'C:\\Program Files\\Unity\\Editor\\Unity.exe':
    logo_small      => 'Unity_small.png',
    logo_medium     => 'Unity_medium.png',
    foreground_text => 'light'
  }
}

class pkgpost_unity_hub( SetupProfile $profile ) {
  ensure_exe_tile {'C:\\Program Files\\Unity Hub\\Unity Hub.exe':
    logo_small      => 'Unity_small.png',
    logo_medium     => 'Unity_medium.png',
    foreground_text => 'light'
  }
}

class pkgpost_blender( SetupProfile $profile) {
  ensure_exe_tile {'C:\\Program Files\\Blender Foundation\\Blender\\blender.exe':
    logo_small      => 'Blender_small.png',
    logo_medium     => 'Blender_medium.png',
    foreground_text => 'light'
  }
}

class pkgpost_arduino( SetupProfile $profile) {
  ensure_exe_tile {'C:\\Program Files (x86)\\Arduino\\arduino.exe':
    logo_small      => 'Arduino_medium.png',
    logo_medium     => 'Arduino_medium.png',
    foreground_text => 'absent'
  }
}

########################################################################################################################
###################################### System Adjustments ##############################################################
########################################################################################################################

class replace_notepad (String $path = '%SystemRoot%\\system32\\NOTEPAD.EXE') {
  $link_dir = "${::windows_env['PROGRAMDATA']}\\NotepadReplacer"
  $link = "${link_dir}\\notepad.exe"
  #create symlink of $path in C:\\ProgramData\\NotepadReplacer\\notepad.exe
  file { 'nodepad_replace_link_dir': ensure => 'directory', path => $link_dir }
    ->
  file { 'nodepad_replace_link': ensure => 'link', path => $link, target => $path }
    ->
  #install package 'notepadreplacer' referencing on the symlink above
  package { 'notepadreplacer':
    ensure          => present,
    install_options => ['-installarguments', "\"/notepad=${link}", '/verysilent"'],
  }
    ->
  #add icon of default editor to Context Menu/Open of text files
  registry_value { 'HKCR\\SystemFileAssociations\\text\\shell\\open\\icon': data => "\"${link}\", 0" }
}


class icons {
  file { 'Icons.puppet':
    ensure             => present,
    path               => "${::windows_env['SYSTEMROOT']}\\Icons.puppet",
    source             => 'puppet:///modules/resources/ico',
    source_permissions => ignore,
    recurse            => true,
    force              => true,
    purge              => true,
  }
}


class win_configure ( SetupProfile $profile ) {
  $icons = getparam(File['Icons.puppet'], 'path')

  $username = $::identity['user']
  $hkcu = "HKU\\${::identity_win['sid']}"
  $localappdata = $::windows_env['LOCALAPPDATA']

  # TODO $is_dev = $profile.any key is 'dev_basics' or starts with 'dev_' is set to true
  $is_dev      = $profile['dev_basics'] == true
  $is_admin    = $profile['administration'] == true
  $is_media    = $profile['media'] == true
  $is_workflow = $profile['workflow'] == true

  # Setting Powershell Execution Policy to unrestricted
  # TODO: sign used powershell script and remove this (or set back to restricted)

  # https://docs.microsoft.com/de-de/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7
  exec { 'Set PowerShell execution policy restricted':
    command  => 'Set-ExecutionPolicy Restricted',
    unless   => 'if ((Get-ExecutionPolicy -Scope LocalMachine).ToString() -eq "Restricted") { exit 0 } else { exit 1 }',
    provider => powershell
  }

  if $is_dev or $is_admin {
    include reg_admin_context_menu

    # CMD: set font Consolas to fix scaling issues
    #TODO: check if "${hkcu}\\Console\\%SystemRoot%_System32_cmd.exe" exists
    #registry_value {"${hkcu}\\Console\\%SystemRoot%_System32_cmd.exe\\FaceName": type => string, data => 'Consolas'}
    #may changing here: HKLM\System\CurrentControlSet\Services\bam\State\UserSettings\S-1-5-21-1523512219-82476422-3388066983-1001\\Device\HarddiskVolume2\Windows\System32\conhost.exe

    # Powershell scripts (*.ps1): add 'Run as administrator' to context menu
    registryx::shell_command{ 'HKCR\\Microsoft.PowerShellScript.1\\shell\\runas':
      command        => 'powershell.exe "-Command" "if((Get-ExecutionPolicy ) -ne \'AllSigned\') { Set-ExecutionPolicy -Scope Process Bypass }; & \'%1\'"',
      mui_verb       => '@shell32.dll,-37448',
      has_lua_shield => '',
    }

    # REGISTER / UNREGISTER  DLL & OCX FILE
    #http://www.eightforums.com/tutorials/40512-register-unregister-context-menu-dll-ocx-files.html
    registryx::class { ['HKCR\\dllfile', 'HKCR\\ocxfile']:
      shell => {
        'Register'   => { command => 'regsvr32.exe "%L"' },
        'Unregister' => { command => 'regsvr32.exe /u "%L"' }
      }
    }
  }

  if $is_admin {
    # add 'Restart Explorer' to context menu of desktop
    registryx::shell_command { 'HKCR\\DesktopBackground\\shell\\Restart Explorer':
      command => 'TSKILL EXPLORER', icon => 'explorer.exe, 0'
    }

    # add quick merge to context menu of reg-files
    registryx::shell_command { 'HKCR\\regfile\\shell\\quickmerge':
      name_or_ref   => 'Quick Merge (no confirm)',
      command       => 'regedit.exe /s "%1"',
      icon          => 'regedit.exe, 0',
      never_default => '',
      extended      => absent,
    }
  }


  if $is_media and $is_workflow {
    #nuke Windows Media Player
    registryx::class { [
        'HKCR\\SystemFileAssociations\\Directory.Audio',
        'HKCR\\SystemFileAssociations\\Directory.Image',
        #'HKCR\\SystemFileAssociations\\Directory.Video',
        'HKCR\\SystemFileAssociations\\audio',
        #'HKCR\\SystemFileAssociations\\video',
      ]: shell => {
        'Enqueue' => { legacy_disable => ''},
        'Play'    => { legacy_disable => ''},
      }
    }

    registry_key { 'HKCR\\SystemFileAssociations\\Directory.Audio\\shellex\\ContextMenuHandlers\\PlayTo': ensure => absent }
    #registry_value { 'HKCR\\SystemFileAssociations\\Directory.Audio\\shellex\\ContextMenuHandlers\\PlayTo\\':
      #ensure => absent, data => '{7AD84985-87B4-4a16-BE58-8B72A5B390F7}' }
  }


  if $is_workflow {
    # remove folders from desktop
    # https://chocolatey.org/packages/desktopicons-winconfig
    package { 'desktopicons-winconfig':
      install_options => ['--params', '"/AllIcons:NO"'],
    }

    #add 'Recycling Bin' to 'This PC'
    registry_key {"${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\MyComputer\\NameSpace\\{645FF040-5081-101B-9F08-00AA002F954E}": ensure => present}

    package { 'taskbar-winconfig':
      ensure          => present,
      install_options => ['--params', '"\'/LOCKED:yes', '/COMBINED:yes', '/PEOPLE:no', '/TASKVIEW:no', '/STORE:no', '/CORTANA:no\'"'],
    }

    # manage elements at 'This PC'
    registryx::this_pc_folder {
      ['Music', 'Pictures', 'Videos']: ensure => ($is_media or !$is_dev) ? {true => present, false => absent };
    }

    # Windows Explorer start to This PC
    registry_value {
      "${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\LaunchTo":
      type => dword, data => 0x00000001 }

    # Add 'Copy Path' to shift context menu
    # Tutorial: https://www.tenforums.com/tutorials/73649-copy-path-add-context-menu-windows-10-a.html
    registry_key   { 'HKCR\\AllFilesystemObjects\\shellex\\ContextMenuHandlers\\CopyAsPathMenu': ensure => present }
    registry_value { 'HKCR\\AllFilesystemObjects\\shellex\\ContextMenuHandlers\\CopyAsPathMenu\\':
      data => '{f3d06e7c-1e45-4a26-847e-f9fcdee59be0}' }

    #enable checkboxes
    registry_value { "${hkcu}\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\AutoCheckSelect":
      type => dword, data => 0x00000001 }

    # keyboard: remap capslock to shift
    registry_value { "${hkcu}\\Keyboard Layout\\Scancode Map":
      # 'HKLM\\SYSTEM\\CurrentControlSet\\Control\\Keyboard Layout\\Scancode Map'
      type => binary, data => '00 00 00 00 00 00 00 00 02 00 00 00 2a 00 3a 00 00 00 00 00' }

    # Hide_Message_-_“Es_konnten_nicht_alle_Netzlaufwerke_wiederhergestellt_werden”
    registry_value { 'HKLM\\SYSTEM\\CurrentControlSet\\Control\\NetworkProvider\\RestoreConnection':
      type => dword, data => '0x00000000' }

    # remove 'Add to library' from context menu
    registry_key   { 'HKCR\\Folder\\ShellEx\\ContextMenuHandlers\\Library Location':
      ensure => absent } # default: data => '{3dad6c5d-2167-4cae-9914-f99e41c12cfa}'

    # Disable AutoPlay for CD/DVD drives and USB flash drives
    # https://docs.microsoft.com/en-us/windows/win32/shell/autoplay-reg
    registry_key { "${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer": ensure => present }
    registry_value { "${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Policies\\Explorer\\NoDriveTypeAutoRun":
      type => dword, data => 0x000000b5 } # default: 0x00000091

    # Remove 'Shortcut' from new links
    registry_value { "${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\link":
      type => binary, data => '00 00 00 00' } # default: data => '1e 00 00 00' or data => '18 00 00 00'

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

    registryx::class{ 'HKCR\\SystemFileAssociations\\text':
      shell => {
        'edit'    => {legacy_disable => ''},
        'print'   => {legacy_disable => ''},
        'printto' => {legacy_disable => ''},
      }
    }
  }

  if $is_admin or $is_dev {
    # show file extensions
    registry_value { "${hkcu}\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\HideFileExt": type => dword, data => 0 }

    # show hidden files and folders
    registry_value { "${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\Hidden": type => dword, data => 1}
  }

  if $is_admin {
    ### Regedit adjustments ################################################################
    $regedit_fav = {
      'App Paths (S)'         => 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\App Paths',
      'Autorun (S)'           => 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run',
      'Autorun (U)'           => 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run',
      'EnvVars (S)'           => 'HKLM\\SYSTEM\\ControlSet001\\Control\\Session Manager\\Environment',
      'EnvVars (U)'           => 'HKCU\\Environment',
      'Sh: *'                 => 'HKCR\\*',
      'Sh: All'               => 'HKCR\\AllFilesystemObjects',
      'Sh: Apps'              => 'HKCR\\Applications',
      'Sh: Directory'         => 'HKCR\\Directory',
      'Sh: Drive'             => 'HKCR\\Drive',
      'Sh: DriveIcons (S)'    => 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\DriveIcons',
      'Sh: Folder'            => 'HKCR\\Folder',
      'Sh: Links'             => 'HKCR\\CLSID\\{00021401-0000-0000-C000-000000000046}',
      'Sh: Network Adapters'  => 'HKCR\\CLSID\\{7007ACC7-3202-11D1-AAD2-00805FC1270E}',
      'Sh: Unknown'           => 'HKCR\\Unknown',
      'Sh: CommandStore (S)'  => 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore',
      'Sh: MIME Types'        => 'HKCR\\MIME\\Database\\Content Type',
      'Sh: MUICache'          => 'HKCU\\Software\\Classes\\Local Settings\\MuiCache',
      'Sh: Open With'         => 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FileExts',
      'Sh: OverlayIcons (S)'  => 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\ShellIconOverlayIdentifiers',
      'Sh: SystemFileAssociations/PerceivedTypes'    => 'HKCR\\SystemFileAssociations',
      'Sh: Shell Folders (S)' => 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders',
      'Sh: Shell Folders (U)' => 'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders',
      'Sh: Shell Icons (S)'   => 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Icons',
      'Firewall Rules (S)'    => 'HKLM\\SYSTEM\\ControlSet001\\services\\SharedAccess\\Parameters\\FirewallPolicy\\FirewallRules',
      'Services (S)'          => 'HKLM\\SYSTEM\\CurrentControlSet\\Services',

    }
    $hkcu_regfav = "${hkcu}\\Software\\Microsoft\\Windows\\CurrentVersion\\Applets\\Regedit\\Favorites"
    registry_key {$hkcu_regfav: ensure => present, purge_values => true }
    $regedit_fav.each |String $key, String $value| { registry_value {"${hkcu_regfav}\\${key}": data => $value } }
  }
}

class reg_admin_context_menu {
  #https://www.howtogeek.com/howto/windows-vista/how-to-clean-up-your-messy-windows-context-menu/

    #$cmd_own_dir = 'powershell -windowstyle hidden -command "Start-Process cmd -ArgumentList \'/c takeown /f \\"%1\\" /r /d y && icacls \\"%1\\" /grant *S-1-3-4:F /t /c /l /q\' -Verb runAs"'
    $cmd_own_dir   = 'cmd.exe /c takeown /f "%1" /r /d y && icacls "%1" /grant administrators:F /t'
    $cmd_own_drive = 'cmd.exe /c takeown /f "%1" /r /d y && icacls "%1" /grant administrators:F /t'
    #$cmd_own_f = 'powershell -windowstyle hidden -command "Start-Process cmd -ArgumentList \'/c takeown /f \\"%1\\" && icacls \\"%1\\" /grant *S-1-3-4:F /t /c /l\' -Verb runAs"'
    $cmd_own_f = 'cmd.exe /c takeown /f "%1" && icacls "%1" /grant administrators:F'
    $reg_own_a = {
      name_or_ref          => 'Take Ownership',
      no_working_directory => '',
      icon                 => 'shell32.dll,-29',
    }
    $menu_position = 'Bottom'


    #Windows.Takeownership.Drive: applies_to => 'NOT (System.ItemPathDisplay:=\"C:\\\")'
    $reg_own_dir_ignore = [
      "${::windows_env['SYSTEMDRIVE']}\\Users",
      $::windows_env['PROGRAMDATA'],
      $::windows_env['PROGRAMFILES'],
      $::windows_env['PROGRAMFILES(X86)'],
      $::windows_env['SYSTEMROOT'],
      "${::windows_env['SYSTEMROOT']}\\System",
      "${::windows_env['SYSTEMROOT']}\\System32",
    ].map |$dir| { "System.ItemPathDisplay:=\\\"${dir}\\\"" }
    $reg_own_drive_ignore = [
      $::windows_env['SYSTEMDRIVE']
    ].map |$dir| { "System.ItemPathDisplay:=\\\"${dir}\\\"" }
    registryx::class { 'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\CommandStore':
      shell => {
        'Windows.Takeownership.Directory' => $reg_own_a + {
          command          => $cmd_own_dir,
          isolated_command => $cmd_own_dir,
          applies_to       => "NOT (${join($reg_own_dir_ignore, ' OR ')})"
        },
        'Windows.Takeownership.Drive'     => $reg_own_a + {
          command          => $cmd_own_drive,
          isolated_command => $cmd_own_drive,
          applies_to       => "NOT (${join($reg_own_drive_ignore, ' OR ')})"
        },
        'Windows.Takeownership.File'      => $reg_own_a + {
          command          => $cmd_own_f,
          isolated_command => $cmd_own_f,
        }
      }
    }

    #add 'Administration' sub menu to context menu of folders and drives
    $reg_admin_menu_dir_and_drive = [
                'Windows.MultiVerb.cmd',
                'Windows.MultiVerb.cmdPromptAsAdministrator',
                '|',
                'Windows.MultiVerb.Powershell',
                'Windows.MultiVerb.PowershellAsAdmin',
                '|',
    ]
    registryx::class {
      ['HKCR\\Directory', 'HKCR\\Directory\\Background']:
      shell => {'Administration' => {
        sub_commands => join($reg_admin_menu_dir_and_drive+['Windows.Takeownership.Directory',],';'),
        icon         => 'imageres.dll,-5323',
        position     => $menu_position,
      }}
    }
    registryx::class {
      ['HKCR\\Drive', 'HKCR\\Drive\\Background']:
      shell => {'Administration' => {
        sub_commands => join($reg_admin_menu_dir_and_drive+['Windows.Takeownership.Drive',],';'),
        icon         => 'imageres.dll,-5323',
        position     => $menu_position,
      }}
    }
    registryx::class { 'HKCR\\*':
      shell => {'Administration' => {
        sub_commands => join(['Windows.Takeownership.File',],';'),
        icon         => 'imageres.dll,-5323',
        position     => $menu_position,
      }}
    }
    registry_key {[
      'HKCR\\Directory\\shell\\Terminals',
      'HKCR\\Directory\\Background\\shell\\Terminals',
      'HKCR\\Drive\\shell\\Terminals',
      'HKCR\\Drive\\Background\\shell\\Terminals',
    ]: ensure => absent }
}

class puppet_conf {
  ini_setting {
    default         : ensure  => present, path => "${::sysenv['pp_confdir']}/puppet.conf", section => 'agent';
    # display current value: puppet agent --configprint runinterval
    'pp_runinterval': setting => 'runinterval', value   => '30m';
    'pp_runtimeout' : setting => 'runtimeout', value   => '12h';
  }
}

class nas_mount {
  # $host='192.168.2.201'
  # $mounts={
  #   "X:" => "\\\\${$host}\\Media",
  #   "Y:" => "\\\\${$host}\\Puppet",
  #   "Z:" => "\\\\${$host}\\Data",
  # }
  # $mounts.each |String $letter, String $unc|{
  #   registry_value { "HKU\\${::identity_win['sid']}\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run\\MountDrive${letter}":
  #       ensure => present, type => string, data => "net use ${letter} ${unc}" }
  #}
  # mount { "X:": ensure => mounted, provider => windows_smb, device => '//BorcklaNAS/Media' }
  # mount { "Y:": ensure => mounted, provider => windows_smb, device => "//BorcklaNAS/Puppet" }
  # mount { "Z:": ensure => mounted, provider => windows_smb, device => "//BorcklaNAS/Data" }
}


########################################################################################################################
###################################### Schedule/configure update tasks #################################################
########################################################################################################################

class package_upgrade_task (
  Array[String] $ignored_packages
) {

  $cup_all_path    ="${::windows_env['PROGRAMDATA']}\\chocolatey.upgradeall.puppet"
  $cup_script      = "${cup_all_path}\\upgrade.ps1"
  $cup_script_pre  = "${cup_all_path}\\preupgrade.ps1"
  $cup_script_post = "${cup_all_path}\\postupgrade.ps1"

  $cup_owner = 'Administrator'
  $cup_group = 'Administratoren' #TODO make this generic

  $cup_script_content = @("EOT"/)
    # do not change this script, the scheduled puppet task may overwrite this changes, instead use one of this files:
    # ${cup_script_pre}
    # ${cup_script_post}
    Set-Location \$PSScriptRoot

    \$excepted_packages = "${join($ignored_packages,',')}"

    . ${cup_script_pre}

    choco upgrade all -y --except=\$excepted_packages

    . ${cup_script_post}
    |-EOT
  file { $cup_all_path: ensure => 'directory', owner => $cup_owner, group => $cup_group }
  file { [$cup_script_pre, $cup_script_post]:
    ensure => 'file', owner => $cup_owner, group => $cup_group, replace => 'no', content => '' }
  file { $cup_script: ensure => 'file', owner => $cup_owner, group => $cup_group, replace => 'yes', content => $cup_script_content }



  scheduled_task { 'Chocolatey Upgrade All':
    enabled   => true,
    command   => "${::system32}\\WindowsPowerShell\\v1.0\\powershell.exe",
    arguments => "-NoProfile -NoLogo -NonInteractive -ExecutionPolicy Bypass -File \"${cup_script}\"",
    user      => 'system',
    trigger   => [{
      schedule    => 'weekly',
      day_of_week => 'mon',
      start_time  => '11:30'
    }],
  }
}



########################################################################################################################
###################################### Node ############################################################################
########################################################################################################################



node default {
  if $::operatingsystem != 'windows'{
    fail("Unsupported OS ${::operatingsystem}")
  }

  # class { '::puppet_agent':
  #   collection      => 'latest',
  #   package_version => '6.6.0',
  # }

  include puppet_conf

  include setup_win
}

