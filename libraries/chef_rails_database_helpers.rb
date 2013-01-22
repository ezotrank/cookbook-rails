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
        template file do
          source "database.yml.erb"
          owner env['user']['login']
          group env['user']['login']
          variables(
          :env => env['name'],
          :adapter => env['database']['adapter'],
          :username => env['database']['username'],
          :password => env['database']['password'],
          :name => env['database']['name']
          )
        end
      end

      def create_database(database, vagrant=false)
        sql_server_connection_info = { :host => "localhost",
          :port => 5432,
          :username => 'postgres',
          :password => node['postgresql']['password']['postgres']}

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
      end

      def drop_database(database)
        sql_server_connection_info = { :host => "localhost",
          :port => 5432,
          :username => 'postgres',
          :password => node['postgresql']['password']['postgres']}

        postgresql_database_user "#{database['username']}" do
          connection sql_server_connection_info
          password "#{database['password']}"
          action :drop
        end
      end
    end
  end
end
