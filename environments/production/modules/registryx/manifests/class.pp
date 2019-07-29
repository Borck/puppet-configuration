#TODO allow to define a member as absent
define registryx::class (
  Optional[String]         $path = undef,
  Optional[String]         $name_or_ref = undef,
  Optional[String]         $default_icon = undef,
  Optional[String]         $content_type = undef,
  Optional[String]         $perceived_type = undef,
  Optional[String]         $root = undef,

  #TODO in shell, support other value types than registry::string
  Optional[
    Hash[
      String,
      Hash[
        String,
        Variant[ String, Numeric, Array[String], Enum['absent']]
      ]
    ]
  ]                        $shell = undef,
  Optional[String]         $shell_default = undef,
) {
  $reg_root = $path ? {
    undef   => $name,
    default => $path
  }
  registry_key   { $reg_root: ensure => present }

  if $name_or_ref != undef {
    registry_value { "${reg_root}\\": data => $name_or_ref }
  }

  if $default_icon != undef {
    registry_key   { "${reg_root}\\defaulticon": ensure => present }
    registry_value { "${reg_root}\\defaulticon\\": data => $default_icon }
  }

  if $content_type != undef {
    registry_value { "${reg_root}\\Content Type": data => $content_type }
  }
  if $perceived_type != undef {
    registry_value { "${reg_root}\\PerceivedType": data => $perceived_type }
  }

  if $shell != undef {
    $shell.each |String $key, Hash[String, Variant[ String, Numeric, Array[String], Hash ]] $value| {
      registryx::shell_command { "${reg_root}\\shell\\${key}": * => $value }
    }
    if $shell_default != undef {
      registry_key   { $reg_shell_root: ensure => present }
      registry_value { "${reg_shell_root}\\": data => $shell_default }
    }
  }
}

