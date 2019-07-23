Facter.add("sysenv") do
  setcode do
    sysenv = {}
    sysenv["pp_confdir"] = Facter::Util::Resolution.exec('puppet agent --configprint confdir')
    sysenv
  end
end