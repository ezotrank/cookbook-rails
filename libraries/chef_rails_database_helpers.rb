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
          variables(:env => env['name'], :vars => env['database'])
        end
      end

    end
  end
end
