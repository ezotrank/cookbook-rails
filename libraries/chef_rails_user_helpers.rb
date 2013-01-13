class Chef
  module RAILS
    module UserHelpers

      # Install all versions of ruby
      def install_rubies
        rubies = []
        node.rails_apps.each do |app|
          rubies << data_bag_item('rails_apps', app)['environments'].map {|e| e['ruby_version']}
        end
        rubies = rubies.flatten.uniq
        node.set['rvm']['rubies'] = rubies
        node.set['rvm']['branch']  = "stable"
        include_recipe "rvm::system"
      end

      # Just create user
      def create_user(params)
        rails_account params['login'] do
          ssh_keys params['ssh_keys']
          action [:create, :modify]
        end

        params['groups'].each do |_group|
          group _group do
            action :modify
            members params['login']
            append true
          end
        end
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
          end
          %x[cat #{tmp_file}| tee -a #{bashrc}]
          FileUtils.rm_rf tmp_file
        end
      end

    end
  end
end
