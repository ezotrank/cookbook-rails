class Chef::Recipe
  include Chef::RAILS::UserHelpers
end

node.rails_apps.each do |app|
  puts "App Name: #{app}"

  rails_app = data_bag_item('rails_apps', app)
  rails_app['environments'].each do |env|
    create_user(env['user'])
  end
end
