# Stop iptables
service "iptables" do
  supports :status => true, :restart => true, :reload => true
  action [ :disable, :stop ]
end

# link "/home/vagrant/project" do
#   to "#{env['folder']}/current"
# end
