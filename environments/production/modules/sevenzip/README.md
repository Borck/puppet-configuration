# 7-Zip module for puppet

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with sevenzip](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with sevenzip](#beginning-with-sevenzip)
4. [Limitations](#limitations)

## Overview

The sevenzip-module installs the application 7-Zip

## Module Description

The sevenzip-module installs 7-Zip on Windows with the chocolatey-module in silent mode.

## Setup

### Setup Requirements

The sevenzip-module uses the chocolatey-chocolatey module

### Beginning with sevenzip

for a simple sevenzip-installation use:

```puppet
    class { "sevenzip" :
    }
```

##### `package_ensure`
One of the following values:
 * **installed:** Installs the current version
 * **latest:** Installs the current version and updates to every new release
 * **'1.0.0':** Installs a specific version
 * **absent:** Removes the application

##### `package_name`
Name of the package in the os-specific package-manager.
In normal circumstances there is no need to change this value.

##### `prerelease`
Wether or not using the prerelease of the package.
This is not available in all providers.

##### `checksum`
Override the maintainer-provided checksum for the package.
This is not available in all providers.


To install a specific version of sevenzip on Windows and override the maintainers checksum:

```puppet
  class {sevenzip:
    package_ensure => '16.4.0.20170506',
    package_name   => ['7zip'],
    prerelease     => false,
    checksum       => 'DrI8v9QAHPiPSpM9qfDYvMqrLj3kNV2HiQ0cZOWVUECmJcGqNSBqEiU9V1lArSRvfEUcT2XMSHHMR/WuiUfvrA=='
  }
```

## Limitations

At the Moment, only windows 7 and windows 10 are supported.
