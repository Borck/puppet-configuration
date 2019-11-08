Facter.add("identity_win") do
  setcode do
    identity_win = {}
    
    if Puppet.features.microsoft_windows?
      whoami=Facter::Util::Resolution.exec('whoami /user /fo csv')
      whoami = whoami.split
      username, sid = whoami[1].split(',')
      identity_win["user"] = username[1..-2]
      identity_win["sid"] = sid[1..-2]
    end
    
    identity_win
  end
end