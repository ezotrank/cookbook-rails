node['rails_apps'].each do |rails_app|
  if data_bag_item('rails_apps', rails_app['name'])['imagemagick']
    case node[:platform]
    when "redhat", "centos", "fedora"
      package 'ImageMagick'
    when "debian", "ubuntu"
      package "imagemagick"
    end
    break
  end
end
