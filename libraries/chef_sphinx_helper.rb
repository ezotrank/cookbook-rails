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
    module SphinxHelpers
      def write_sphinx_config(env)
        directory File.join(env['folder'], 'shared/sphinx_index') do
          owner env['user']['login']
          group env['user']['login']
          mode 00755
        end

        template File.join(env['folder'], 'shared/config/sphinx.yml') do
          source "sphinx.yml.erb"
          variables(
            :env => env['name'],
            :port => env['sphinx']['port'],
            :root_folder => env['folder']
          )
          owner env['user']['login']
          group env['user']['login']
          mode "0644"
        end

      end
    end
  end
end
