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
    module UserHelpers

      def ssh_strick_key(login)
        execute "Strick KnowHost key checking" do
          user login
          group login
          cwd "/home/#{login}"
          command "echo 'StrictHostKeyChecking no' > .ssh/config"
        end
      end

      # Just create user
      def create_user(params)
	rails_account params['login'] do
	  ssh_keys params['ssh_keys']
	  action [:create, :modify]
	  ssh_keygen false
	end

	params['groups'].each do |_group|
	  group _group do
	    action :modify
	    members params['login']
	    append true
	  end
	end if params['groups']
      end

    end
  end
end
