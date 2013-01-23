class Chef::Recipe
  include Chef::Rails::UserHelpers
  include Chef::Rails::DatabaseHelpers
  include Chef::Rails::DeployHelpers
  include Chef::Rails::PackagesHelpers
end

return if node['rails_apps'].nil?

include_recipe "postgresql::ruby"

# Install all rubies versions from all rails apps
install_rubies
install_imagemagick

node['rails_apps'].each do |app|
  puts "App Name: #{app}"

  rails_app = data_bag_item('rails_apps', app)
  rails_app['environments'].each do |env|
    unless env['vagrant']
      create_user(env['user'])
      ssh_strick_key(env['user']['login'])
    end

    default_user_ruby(env['user']['login'], env['ruby_version'])
    create_necessary_folders(env)
    write_database_yaml(env)
    create_database(env['database'], env['vagrant'])
    if env['vagrant']
      include_recipe "rails::vagrant"
    else
      create_rvm_wrapper(env)
      write_init_script(rails_app, env)
      write_nginx_config(rails_app, env)
      deploy_project(rails_app, env)
    end
  end
end
