define registryx::shell_command (
  Optional[String]                        $name_or_ref                   = undef,
  Optional[String]                        $path                      = undef,
  Optional[String]                        $mui_verb                  = undef,
  Optional[String]                        $icon                      = undef,
  Optional[Enum['absent', 'present', '']] $extended                  = undef,
  Optional[Enum['absent', 'present', '']] $has_lua_shield            = undef,
  Optional[Enum['absent', 'present', '']] $never_default             = undef,
  Optional[Enum['absent', 'present', '']] $no_working_directory      = undef,
  Optional[Enum['absent', 'present', '']] $legacy_disable            = undef,
  Optional[String]                        $position                  = undef,
  Optional[String]                        $applies_to                = undef,
  Optional[String]                        $command                   = undef,
  Optional[String]                        $isolated_command          = undef,
  Optional[String]                        $extended_sub_commands_key = undef,
  Optional[String]                        $sub_commands              = undef,
  Optional[Hash[
    String,
    Variant[
      String,
      Numeric,
      Array[String],
      Hash
  ]]]                                     $sub_shell = undef,
){
  $reg_shell_root = $path ? {
    undef   => $name,
    name_or_ref => $path
  }

  if ($command != undef) or
    ($isolated_command != undef) {
    registry_key { "${reg_shell_root}\\command": ensure => present }
  } else {
    registry_key { $reg_shell_root: ensure => present }
  }

  if $command != undef {
    registry_value { "${reg_shell_root}\\command\\": data => $command }
  }
  if $name_or_ref != undef {
    registry_value { "${reg_shell_root}\\": data => $name_or_ref }
  }
  if $icon != undef {
    registry_value { "${reg_shell_root}\\Icon": data => $icon }
  }
  if $extended != undef {
    $extended_real = $extended ? { 'absent' => absent, default => present }
    registry_value { "${reg_shell_root}\\Extended":
      ensure => $extended_real }
  }
  if $has_lua_shield != undef {
    $has_lua_shield_real = $has_lua_shield ? { 'absent' => absent, default => present }
    registry_value { "${reg_shell_root}\\HasLUAShield": ensure => $has_lua_shield_real  }
  }
  if $never_default != undef {
    $never_default_real = $never_default ? { 'absent' => absent, default => present }
    registry_value { "${reg_shell_root}\\NeverDefault": ensure => $never_default_real  }
  }
  if $no_working_directory != undef {
    $no_working_directory_real = $no_working_directory ? { 'absent' => absent, default => present }
    registry_value { "${reg_shell_root}\\NoWorkingDirectory": ensure => $no_working_directory_real  }
  }
  if $legacy_disable != undef {
    $legacy_disable_real = $legacy_disable ? { 'absent' => absent, default => present }
    registry_value { "${reg_shell_root}\\LegacyDisable": ensure => $legacy_disable_real  }
  }
  if $mui_verb != undef {
    registry_value { "${reg_shell_root}\\MUIVerb": data => $mui_verb }
  }
  if $extended_sub_commands_key != undef {
    registry_value { "${reg_shell_root}\\ExtendedSubCommandsKey": data => $extended_sub_commands_key }
  }
  if $sub_commands != undef {
    registry_value { "${reg_shell_root}\\SubCommands": data => $sub_commands }
  }
  if $isolated_command != undef {
    registry_value { "${reg_shell_root}\\command\\IsolatedCommand": data => $isolated_command }
  }
  if $position != undef {
    registry_value { "${reg_shell_root}\\Position": data => $position }
  }
  if $applies_to != undef {
    registry_value { "${reg_shell_root}\\AppliesTo": data => $applies_to }
  }
  if $sub_shell != undef {
    $sub_shell.each |String $key, Hash[String, Variant[ String, Numeric, Array[String], Hash ]] $value| {
      registryx::shell_command { "${reg_shell_root}\\shell\\${key}":
        * => $value }
    }
  }
}
