chef_gem 'pg'

class Chef::Recipe
  include Chef::Rails::UserHelpers
  include Chef::Rails::DatabaseHelpers
  include Chef::Rails::DeployHelpers
  include Chef::Rails::PackagesHelpers
end

# Install all rubies versions from all rails apps
install_rubies
install_imagemagick

node.rails_apps.each do |app|
  puts "App Name: #{app}"

  rails_app = data_bag_item('rails_apps', app)
  rails_app['environments'].each do |env|
    create_user(env['user'])
    ssh_strick_key(env['user']['login'])
    default_user_ruby(env['user']['login'], env['ruby_version'])
    create_necessary_folders(env)
    write_database_yaml(env)
    create_database(env['database'])
    deploy_project(rails_app, env)
  end
end
