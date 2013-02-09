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
    module NginxHelpers

      def write_nginx_config(app, env)
        config_file = File.join('/etc/nginx/sites-available', "#{app['id']}_#{env['name']}.conf")
        # Change nginx config
        template config_file do
          source "nginx_site.conf.erb"
          variables(
          :app_name      => "#{app['id']}_#{env['name']}.conf",
          :urls          => env['urls'],
          :root_folder   => env['folder'],
          :nginx_server  => env['nginx_server']
          )
          owner 'root'
          group 'root'
          mode "0644"
          backup false

          only_if { ::File.exist?('/etc/init.d/nginx') }
        end

        nginx_site File.basename(config_file)
      end

      def add_under_constraction_site
        directory "/var/www/under_construction" do
          mode 0755
          action :create
          recursive true
        end

        %w[index.html under-construction.gif].each do |f|
          cookbook_file "/var/www/under_construction/#{f}" do
            source "under_construction/#{f}"
            mode 0755
          end
        end
      end

    end
  end
end
