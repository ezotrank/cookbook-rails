ext_packages = []

node['rails_apps'].each do |rails_app|
  ext_packages << data_bag_item('rails_apps', rails_app['name'])['ext_packages']
end

return if ext_packages.empty?
ext_packages = ext_packages.flatten.uniq

ext_packages.each do |pack|
  if pack == 'rmagick'
    package 'ruby-RMagick'
    package 'ImageMagick-devel'
  elsif pack == 'imagemagick'
    package case node[:platform]
            when "redhat", "centos", "fedora" then 'ImageMagick'
            when "debian", "ubuntu" then "imagemagick"
            end
  end
end
