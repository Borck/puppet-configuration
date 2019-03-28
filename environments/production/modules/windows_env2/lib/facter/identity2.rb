Facter.add("identity2") do
  setcode do
    identity2 = {}
    whoami=Facter::Util::Resolution.exec('whoami /user /fo csv')
    whoami = whoami.split
    username, sid = whoami[1].split(',')
    identity2["user"] = username[1..-2]
    identity2["sid"] = sid[1..-2]
    identity2
  end
end