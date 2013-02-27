class Chef::Recipe
  include Chef::Rails::UserHelpers
  include Chef::Rails::DatabaseHelpers
  include Chef::Rails::DeployHelpers
  include Chef::Rails::PackagesHelpers
  include Chef::Rails::NginxHelpers
end

return if node['rails_apps'].nil?

include_recipe 'rails::install_v8'
include_recipe 'rails::install_ext_packages'

node['rails_apps'].each do |app|

  rails_app = data_bag_item('rails_apps', app['name'])
  rails_app['environments'].map {|h| h if app['env'].include?(h['name'])}.compact.each do |env|

    unless env['vagrant']
      create_user(env['user'])
      ssh_strick_key(env['user']['login'])
    end

    create_necessary_folders(env)
    write_database_yaml(env)

    create_project_link(rails_app, env)
    write_robots_txt(env)

    create_rvm_wrapper(env)
    write_init_script(rails_app, env)
    write_nginx_config(rails_app, env)
    write_unicorn_config(env)
  end
end
