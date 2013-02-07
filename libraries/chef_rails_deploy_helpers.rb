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
    module DeployHelpers

      def create_project_link(app, env)
        # Create symlink to home direcory
        link File.join('/home', env['user']['login'], "#{app['id']}_#{env['name']}") do
          to env['folder']
          user env['user']['login']
          group env['user']['login']
        end
      end

      def write_unicorn_config(env)
        template File.join(env['folder'], 'shared/config/chef_unicorn.rb') do
          source "unicorn_config.rb.erb"
          variables(
          :root_folder => env['folder'],
          :unicorn_workers => env['unicorn_workers']
          )
          owner env['user']['login']
          group env['user']['login']
          mode "0644"
          backup false
        end
      end

      def create_rvm_wrapper(env)
        directory File.join(env['folder'], 'shared/scripts') do
          owner env['user']['login']
          group env['user']['login']
          mode 0755
          action :create
        end

        template File.join(env['folder'], 'shared/scripts/rvm_wrapper.sh') do
          source "rvm_wrapper.sh.erb"
          variables(:ruby_version => env['ruby_version'])
          owner env['user']['login']
          group env['user']['login']
          mode "0755"
          backup false
        end
      end

      def write_init_script(app, env)
        template File.join('/etc/init.d', "#{app['id']}_#{env['name']}") do
          source "init_script.erb"
          variables(
          :application_name => app['id'],
          :root_folder      => env['folder'],
          :rails_env        => env['name'],
          :ruby_version     => env['ruby_version'],
          :user             => env['user']['login']
          )
          owner env['user']['login']
          group env['user']['login']
          mode "0755"
          backup false
        end

        service "#{app['id']}_#{env['name']}" do
          supports :status => true, :restart => true, :reload => true
          action :enable
        end
      end

      def create_necessary_folders(env)
        user_name = env['user']['login']
        group_name = env['user']['login']

        directory "/var/www" do
          owner "root"
          group "root"
          mode "0755"
          action :create
        end

        directory env['folder'] do
          owner user_name
          group group_name
          mode "0755"
          action :create
        end

        ['shared', 'shared/log', 'shared/system', 'shared/pids', 'shared/config', 'shared/assets'].each do |folder_name|
          directory File.join(env['folder'], folder_name) do
            owner user_name
            group group_name
            mode "0755"
            recursive true
            action :create
          end
        end
      end

    end
  end
end
