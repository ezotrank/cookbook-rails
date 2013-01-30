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

      def deploy_project(app, env)
        sql_server_connection_info = { :host => "localhost",
          :port => 5432,
          :username => 'postgres',
          :password => node['postgresql']['password']['postgres']}
        wrapper_path = File.join(env['folder'], 'shared/scripts/rvm_wrapper.sh')
        deploy_log = File.join(env['folder'], 'shared/log/deploy.log')
        execute "echo -E > #{deploy_log}"

        deploy_revision env['folder'] do
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
          migration_command "#{wrapper_path} bundle exec rake db:migrate --trace &>> #{deploy_log}"
          restart_command "/etc/init.d/#{app['id']}_#{env['name']} restart &>> #{deploy_log}"
          symlinks "system" => "public/system",
                   "pids"   => "tmp/pids",
                   "log"    => "log",
                   "assets" => "public/assets"

          before_migrate do

            run "git rev-parse HEAD > version"

            execute "Bundle install" do
              command <<-eos
                       #{wrapper_path} bundle install --gemfile #{File.join(release_path, 'Gemfile')} \
                                                      --path #{File.join env['folder'], 'shared/bundle'} \
                                                      --deployment --without #{env['bundle_without']} &>> #{deploy_log}
                      eos
              cwd release_path
              user env['user']['login']
              group env['user']['login']
            end

            postgresql_database_user "#{env['database']['username']}" do
              connection sql_server_connection_info
              password "#{env['database']['password']}"
              action :create
            end

            execute "stop application service - #{app['id']}_#{env['name']} stop" do
              command "/etc/init.d/#{app['id']}_#{env['name']} stop &>> #{deploy_log}"
              only_if do
                ::File.exist?("/etc/init.d/#{app['id']}_#{env['name']}") &&
                  ::File.exist?(File.join(env['folder'], 'shared/pids/unicorn.pid'))
              end
            end if env['flush_db'] && env['flush_db'] == true

            postgresql_database env['database']['name'] do
              connection sql_server_connection_info
              owner env['database']['username']
              action (env['flush_db'] && env['flush_db'] == true) ? [:drop, :create] : [:create]
            end

          end

          before_restart do

            execute "Load seed data" do
              command "#{wrapper_path} bundle exec rake RAILS_ENV=#{env['name']} db:seed --trace &>> #{deploy_log}"
              cwd release_path
              user env['user']['login']
              group env['user']['login']
            end if env['load_seed'] && env['load_seed'] == true

            execute "Load sample data" do
              command "#{wrapper_path} bundle exec rake RAILS_ENV=#{env['name']} db:load_sample --trace &>> #{deploy_log}"
              cwd release_path
              user env['user']['login']
              group env['user']['login']
            end if env['load_sample'] && env['load_sample'] == true


            directory File.join(release_path, 'config/unicorn') do
              owner env['user']['login']
              group env['user']['login']
              mode 0755
              action :create
            end

            if env['development_mode'] && env['development_mode'] = true
              template File.join(release_path, 'config/unicorn/chef_unicorn.rb') do
                source "unicorn_config_development.rb.erb"
                variables(
                :root_folder => env['folder'],
                :unicorn_workers => env['unicorn_workers']
                )
                owner env['user']['login']
                group env['user']['login']
                mode "0644"
                backup false
              end
            else
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

              # Assets precompile
              # We should recompile assets when count of all releases < 2,
              # if shared assets folder is blank and if in new relase has
              # something new in folders vendor/assets or app/assets
              if all_releases.size < 2 || `ls #{env['folder']}/shared/assets|wc -l`.to_i <= 0 ||
                  `cd #{release_path} && git log $(cat #{previous_release_path}/version).. vendor/assets app/assets | wc -l`.to_i > 0
                Chef::Log.info "We found changes in assets, let's recompile their"
                run "#{wrapper_path} bundle exec rake assets:precompile --trace &>> #{deploy_log}"
              else
                Chef::Log.info "Not changes in assets"
              end
            end

          end

          after_restart do

            # Create symlink to home direcory
            link File.join('/home', env['user']['login'], "#{app['id']}_#{env['name']}") do
              to env['folder']
              user env['user']['login']
              group env['user']['login']
            end

          end

        end
      end
    end
  end
end
