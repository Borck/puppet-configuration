# == Class: sevenzip::install
#
# This is the install-class to install the sevenzip-application
#
# === Parameters
#
# See the init-class.
#
# === Variables
#
# === Examples
#
# === Authors
#
# Martin Schneider <martin@dermac.de>
#
# === Copyright
#
# Copyright 2017 Martin Schneider
#
class sevenzip::install inherits sevenzip {

  case $::os['name'] {
    'windows': {
      case $::os['release']['major'] {
        '7', '10': {
          # ensure chocolatey is installed and configured
          include chocolatey

          # Initialise Install-Options-Array
          $install_options_0 = []
          if ($sevenzip::prerelease) {
            $install_options_1 = concat($install_options_0, '-pre')
          }
          else {
            $install_options_1 = $install_options_0
          }
          if ($sevenzip::checksum) {
            $install_options_2 = concat($install_options_1, ['--download-checksum', $sevenzip::checksum])
          }
          else {
            $install_options_2 = $install_options_1
          }
          $install_options = $install_options_2

          package { $sevenzip::package_name:
            ensure            => $sevenzip::package_ensure,
            provider          => 'chocolatey',
            install_options   => $install_options,
            uninstall_options => ['-r'],
          }
        }
        default: {
          fail("The ${module_name} module is not supported on Windows Version ${::operatingsystemmajrelease} based system.")
        }
      }
    }
    default: {
      fail("The ${module_name} module is not supported on an ${::osfamily} based system.")
    }
  }
}
