rubies = []
node['rails_apps'].each do |rails_app|
  data_bag_item('rails_apps', rails_app['name'])['environments'].each do |env|
    rubies << env['ruby_version'] if rails_app['env'].include?(env['name'])
  end
end
Chef::Log.info "This ruby versions will be installed on this node #{rubies}"
return if rubies.empty?
rubies = rubies.flatten.uniq
node.set['rvm']['rubies'] = rubies
node.set['rvm']['branch']  = "stable"
node.set['rvm']['global_gems'] = node['rvm']['global_gems'] | [{'name' => 'bluepill'}]
include_recipe "rvm::system"
include_recipe 'rvm::gem_package'

