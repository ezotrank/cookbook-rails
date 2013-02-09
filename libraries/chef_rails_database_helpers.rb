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
    module DatabaseHelpers

      def write_database_yaml(env)
        file = File.join(env['folder'], 'shared/config/database.yml')
        template_file = case env['database']['adapter']
                        when 'mysql' then 'database_mysql.yml.erb'
                        when 'postgresql' then 'database_postgresql.yml.erb'
                        end
        template file do
          source template_file
          owner env['user']['login']
          group env['user']['login']
          variables(
          :env => env['name'],
          :username => env['database']['username'],
          :password => env['database']['password'],
          :name => env['database']['name']
          )
        end
      end

      def create_database(database, vagrant=false)
        db_name, port, username, password = case database['adapter']
                                            when 'mysql'
                                              [ 'mysql', 3306, 'root', node['mysql']['server_root_password']]
                                            when 'postgresql'
                                              [ 'postgresql', 5432, 'postgres', node['postgresql']['password']['postgres'] ]
                                            end

        sql_server_connection_info = { :host => "localhost",
                                       :port => port,
                                       :username => username,
                                       :password => password }

        if db_name == 'postgresql'
          postgresql_database_user "#{database['username']}" do
            connection sql_server_connection_info
            password "#{database['password']}"
            action :create
          end

          postgresql_database database['name'] do
            connection sql_server_connection_info
            owner database['username']
            action :create
          end

          postgresql_database "grant permission to createdb for vagrant user" do
            connection sql_server_connection_info
            sql "ALTER USER #{database['username']} SUPERUSER;"
            action :query
          end if vagrant

        else
          mysql_database_user "#{database['username']}" do
            connection sql_server_connection_info
            password "#{database['password']}"
            action :create
          end

          mysql_database database['name'] do
            connection sql_server_connection_info
            owner database['username']
            action :create
          end

          mysql_database "grant permission to createdb for vagrant user" do
            connection sql_server_connection_info
            sql "GRANT ALL PRIVILEGES ON *.* TO '#{database['username']}'@'localhost' WITH GRANT OPTION;"
            action :query
          end if vagrant
        end

      end

    end
  end
end
