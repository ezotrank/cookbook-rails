packages = case node['platform_family']
           when "rhel", "fedora", "suse"
             ['v8', 'v8-devel']
           when "debian"
             ['libv8-dev']
           end

packages.each do |v8_pack|
  package v8_pack
end
