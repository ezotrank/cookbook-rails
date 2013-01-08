class Chef
  module RAILS
    module UserHelpers

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

    end
  end
end
