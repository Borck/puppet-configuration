# == Class: sevenzip
#
# Install and configure the sevenzip-application (http://www.7-zip.de/).
#
# === Parameters
#
# [*package_ensure*]
#   One of the following values
#   installed|latest|'1.0.0'|absent
# [*$package_name*]
#   Name of the package in the operatingsystem, or in case of Windows
#   the packagename in chocolatey
# [*$prerelease*]
#   If supported you can install a prerelease
#   (for example on windows/chocolatey an uploaded but not approved version)
#   true|false
# [*$checksum*]
#   If supported you can overwrite the checksum of the downloaded file
#   (for example on windows/chocolatey you can overwrite the checksum
#   provided by the maintainer)
#
# === Variables
#
# === Examples
#
#  class { 'sevenzip': }
#
# === Authors
#
# Martin Schneider <martin@dermac.de>
#
# === Copyright
#
# Copyright 2017 Martin Schneider
#
class sevenzip (
  $package_ensure     = $sevenzip::params::package_ensure,
  $package_name       = $sevenzip::params::package_name,
  $prerelease         = $sevenzip::params::prerelease,
  $checksum           = $sevenzip::params::checksum,
) inherits sevenzip::params {

  validate_array($package_name)
  validate_bool($prerelease)

  anchor { 'sevenzip::begin': }
  -> class { '::sevenzip::install': }
  -> class { '::sevenzip::config': }
  anchor { 'sevenzip::end': }

}
