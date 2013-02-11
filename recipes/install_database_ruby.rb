databases = []
node['rails_apps'].each do |rails_app|
  databases << data_bag_item('rails_apps', rails_app['name'])['database']
end
databases.uniq.each do |database|
  case database
  when "mysql" then include_recipe "mysql::ruby"
  when "postgresql"
    if(node['postgresql']['enable_pgdg_yum'])
      include_recipe 'postgresql::yum_pgdg_postgresql'
    end
    include_recipe "postgresql::ruby"
  end
end
