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

        ['shared', 'shared/log', 'shared/system', 'shared/pids', 'shared/config'].each do |folder_name|
          directory File.join(env['folder'], folder_name) do
            owner user_name
            group group_name
            mode "0755"
            recursive true
            action :create
          end
        end
      end

      def deploy_project(app, env)
        deploy env['folder'] do
          repo app['repo']
          revision env['revision']
          user env['user']['login']
          group env['user']['login']
          enable_submodules true
          environment({
                        "RAILS_ENV" => env['name'],
                        "RAILS_GROUPS" => "assets"
                      })
          shallow_clone true
          migrate true
          migration_command "./script/rvm_wrapper.sh bundle exec rake db:migrate"
          restart_command "/etc/init.d/#{app['id']}_#{env['name']} restart"
          before_migrate do

            template File.join(release_path, 'script/rvm_wrapper.sh') do
              source "rvm_wrapper.sh.erb"
              variables(:ruby_version => env['ruby_version'])
              owner env['user']['login']
              group env['user']['login']
              mode "0755"
              backup false
            end

            rvm_shell "Bundle install and assets precompile" do
              ruby_string env['ruby_version']
              cwd release_path
              user env['user']['login']
              group env['user']['login']
              common_groups = %w{development test cucumber staging}

              code %{
                bundle install --deployment --path #{File.join env['folder'], 'shared/bundle'} --without #{common_groups.join(' ')}
              }
            end

            sql_server_connection_info = { :host => "localhost",
                                           :port => 5432,
                                           :username => 'postgres',
                                           :password => node['postgresql']['password']['postgres']}

            postgresql_database_user "#{env['database']['username']}" do
              connection sql_server_connection_info
              password "#{env['database']['password']}"
              action :create
            end

            postgresql_database env['database']['name'] do
              connection sql_server_connection_info
              owner env['database']['username']
              action :create
            end

            if env['load_ext_once'] == false
              processes_list = "/tmp/mysql_kill_connections_#{env['database']['name']}_#{rand(1..9999999).to_s}"
              Chef::Log.info "Drop all connection on database #{env['database']['name']}"
              postgresql_database "drop all connection" do
                connection sql_server_connection_info
                sql <<-eos
                       select concat('KILL ',id,';') from information_schema.processlist where db='#{env['database']['name']}'
                       into outfile '#{processes_list}';
                       source #{processes_list};
                    eos
                action :query
              end

              Chef::Log.info "Drop and then create database #{env['database']['name']}"
              postgresql_database env['database']['name'] do
                connection sql_server_connection_info
                owner env['database']['username']
                action [:drop, :create]
              end
            end

          end

          before_restart do

            tasks = case env['load_ext_data']
                    when "seed" then "db:seed"
                    when "load_sample" then "db:seed db:load_sample"
                    when "full" then "db:seed db:load_sample"
                    else
                      nil
                    end

            if tasks
              execute "Load seeds" do
                command "./script/rvm_wrapper.sh bundle exec rake RAILS_ENV=#{env['name']} #{tasks}"
                cwd release_path
                user env['user']['login']
                group env['user']['login']
                creates(File.join(release_path, 'shared/pids/seed.lock')) if (env['load_ext_once'] && env['load_ext_once'] == true)
              end
            end

            # Update Unicorn config
            template File.join(release_path, 'config/unicorn/chef_unicorn.rb') do
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

            # Update init script
            template File.join('/etc/init.d', "#{app['id']}_#{env['name']}") do
              source "init_script.erb"
              variables(
              :application_name => app['id'],
              :root_folder => env['folder'],
              :rails_env => env['name'],
              :ruby_version => env['ruby_version'],
              :user => env['user']['login']
              )
              owner env['user']['login']
              group env['user']['login']
              mode "0755"
              backup false
            end

            # Assets precompile
            execute "Assets precompile" do
              command "./script/rvm_wrapper.sh bundle exec rake RAILS_ENV=#{env['name']} assets:precompile"
              cwd release_path
              user env['user']['login']
              group env['user']['login']
            end

            # Change nginx config
            template File.join('/etc/nginx/conf.d', "#{app['id']}_#{env['name']}.conf") do
              source "nginx_site.conf.erb"
              variables(
              :app_name => "#{app['id']}_#{env['name']}.conf",
              :urls => env['urls'],
              :root_folder => env['folder'],
              )
              owner 'root'
              group 'root'
              mode "0644"
              backup false
            end

          end
        end

      end
    end
  end
end
