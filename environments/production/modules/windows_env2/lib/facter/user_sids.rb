Facter.add("user_sids") do
  setcode do
    sids = {}
    user_list=Facter::Util::Resolution.exec('wmic useraccount where LocalAccount="True" get name,sid /format:csv')
    user_list = user_list.split
    user_list.each do |userline|
      node, username, sid = userline.split(',')
      sids[username] = sid
    end
    sids
  end
end