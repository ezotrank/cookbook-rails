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

      # Define default user ruby
      def default_user_ruby(user, ruby_version)
	find_string = "export RVM_DEFAULT=#{ruby_version}"
	bashrc = File.join("/home", user, ".bashrc")

	if %x[grep "#{find_string}" #{bashrc}].empty?
	  tmp_file = "/tmp/#{user}_#{ruby_version}"
	  template tmp_file do
	    source "default_user_ruby.erb"
	    variables({ :ruby_version => ruby_version })
            mode '0755'
	  end
          execute "Append default ruby version to user" do
            command "cat #{tmp_file} | tee -a #{bashrc} &>/dev/null"
            user user
          end
	  FileUtils.rm_rf tmp_file
	end
      end

    end
  end
end
