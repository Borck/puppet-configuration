# == Class: sevenzip::params
#
# This is the paramter-class to configure the sevenzip-module
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
class sevenzip::params {

  $default_package_name = ['7zip']
  $package_ensure       = latest
  $prerelease           = false
  $checksum             = false

  case $::os['name'] {
    'windows': {
      case $::os['release']['major'] {
        '7', '10': {
          $package_name = $default_package_name
        }
        default: {
          fail("The ${module_name} module is not supported on Windows Version ${::os['release']['full']} based system.")
        }
      }
    }
    default: {
      fail("The ${module_name} module is not supported on an ${::os['name']} based system.")
    }
  }
}
