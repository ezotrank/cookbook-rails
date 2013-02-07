#
# Cookbook Name:: rails
#
# Author:: Maxim Kremenev <ezo@kremenev.com>
#
# Copyright 2013, Maxim Kremenev
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class Chef
  module Rails
    module PackagesHelpers
      def install_rvm_wrapper(env, path)
        template File.join(path, 'script/rvm_wrapper.sh') do
          source "rvm_wrapper.sh.erb"
          variables(:ruby_version => env['ruby_version'])
          owner env['user']['login']
          group env['user']['login']
          mode "0755"
          backup false
        end
      end

      # Install all versions of ruby
      def install_rubies
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
        include_recipe "rvm::system"
      end

      def install_database_ruby
        databases = []
        node['rails_apps'].each do |rails_app|
          databases << data_bag_item('rails_apps', rails_app['name'])['database']
        end
        databases.uniq.each do |database|
          case database
          when "mysql" then include_recipe "mysql::ruby"
          when "postgresql" then include_recipe "postgresql::ruby"
          end
        end
      end

      def install_imagemagick
        node['rails_apps'].each do |rails_app|
          if data_bag_item('rails_apps', rails_app['name'])['imagemagick']
            package 'ImageMagick'
            package 'ImageMagick-devel'
            break
          end
        end
      end

    end
  end
end
