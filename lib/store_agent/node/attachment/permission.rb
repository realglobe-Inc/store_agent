module StoreAgent
  module Node
    class Permission < Attachment
      def allow?(permission_name)
        if object.user.super_user?
          return data["superuser"][permission_name]
        end
        object.user.identifiers.reverse.each do |identifier|
          if (user_permission = data["users"][identifier]) && user_permission.key?(permission_name)
            return user_permission[permission_name]
          end
        end
        !!data["guest"][permission_name]
      end

      def set!(identifier, permission_values, options = {})
        user_permission = (data["users"][identifier] ||= {})
        permission_values.each do |permission_name, value|
          user_permission[permission_name] = value
        end
        save
        if options[:recursive]
          object.children.each do |child|
            child.permission.set!(identifier, permission_values, options)
          end
        end
      end

      def unset!(identifier, permission_names, options = {})
        permission_names = [permission_names].flatten
        if user_permission = data["users"][identifier]
          user_permission.delete_if do |key, _|
            permission_names.include?(key)
          end
          save
        end
        if options[:recursive]
          object.children.each do |child|
            child.permission.unset!(identifier, permission_names, options)
          end
        end
      end

      def file_path
        "#{@object.workspace.permission_dirname}#{@object.path}#{StoreAgent.config.permission_extension}"
      end

      private

      def initial_data
        user_permission = {}
        if !(object.user.super_user? || object.user.guest?)
          user_permission[@object.user.identifier] = StoreAgent.config.default_owner_permission
        end
        {
          "superuser" => StoreAgent.config.super_user_permission,
          "users" => user_permission,
          "guest" => StoreAgent.config.default_guest_permission
        }
      end
    end
  end
end
