class Chef::Recipe
  include Chef::RAILS::UserHelpers
end

# Install all rubies versions from all rails apps
install_rubies

node.rails_apps.each do |app|
  puts "App Name: #{app}"
  rails_app = data_bag_item('rails_apps', app)
  rails_app['environments'].each do |env|
    create_user(env['user'])
    default_user_ruby(env['user']['login'], env['ruby_version'])
  end
end
