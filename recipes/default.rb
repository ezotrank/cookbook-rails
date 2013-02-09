class Chef::Recipe
  include Chef::Rails::UserHelpers
  include Chef::Rails::DatabaseHelpers
  include Chef::Rails::DeployHelpers
  include Chef::Rails::PackagesHelpers
  include Chef::Rails::NginxHelpers
  include Chef::Rails::SphinxHelpers
end

return if node['rails_apps'].nil?

include_recipe 'rails::install_database_ruby'
include_recipe 'rails::install_rubies'
include_recipe 'rails::install_v8'
include_recipe 'rails::install_imagemagick'

node['rails_apps'].each do |app|

  rails_app = data_bag_item('rails_apps', app['name'])
  rails_app['environments'].map {|h| h if app['env'].include?(h['name'])}.compact.each do |env|

    unless env['vagrant']
      create_user(env['user'])
      ssh_strick_key(env['user']['login'])
    end

    default_user_ruby(env['user']['login'], env['ruby_version'])
    create_necessary_folders(env)
    write_database_yaml(env)
    create_database(env['database'], env['vagrant'])
    create_project_link(rails_app, env)
    write_robots_txt(env)
    write_sphinx_config(env) if env['sphinx']
    if env['vagrant']
      include_recipe "rails::vagrant"
    else
      create_rvm_wrapper(env)
      write_init_script(rails_app, env)
      write_nginx_config(rails_app, env)
      write_unicorn_config(env)
    end
  end
end
