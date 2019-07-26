# manage elements at 'This PC'
# how to hide element in 'This PC': http://www.thewindowsclub.com/remove-the-folders-from-this-pc-windows-10
# TODO move to method
# TODO partally use current user instead of local machine?

define registryx::this_pc_namespace (
  Enum['present', 'hidden']         $ensure
) {
  $reg_key_h = "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FolderDescriptions\\${name}\\PropertyBag\\ThisPCPolicy"
  if $ensure == 'hidden' {
    registry_key { [$reg_key_h, "32:${reg_key_h}"]: ensure => present }
  } else {
    $reg_key_present = "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\MyComputer\\NameSpace\\${name}"
    registry_key { [ $reg_key_present, "32:${reg_key_present}" ]: ensure => present }
  }
  registry_value { ["${reg_key_h}\\Hide", "32:${reg_key_h}\\Hide"]:
    ensure => ($ensure ? {'hidden' => present, 'present' => absent}) }
}

