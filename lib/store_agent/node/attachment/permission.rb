module StoreAgent
  module Node
    class Permission < Attachment
      def allow?(permission_name)
        case
        when current_user.super_user?
          true
        when identifier = permission_defined_user_identifier(permission_name)
          data["users"][identifier][permission_name]
        else
          !!data["guest"][permission_name]
        end
      end

      def set!(identifier: nil, permission_values: {})
        user_permission = (data["users"][identifier] ||= {})
        permission_values.each do |permission_name, value|
          user_permission[permission_name] = value
        end
        save
      end

      def unset!(identifier: nil, permission_names: [])
        permission_names = [permission_names].flatten
        if user_permission = data["users"][identifier]
          user_permission.delete_if do |permission_name, _|
            permission_names.include?(permission_name)
          end
          if user_permission.empty?
            data["users"].delete(identifier)
          end
          save
        end
      end

      def base_path
        "#{@object.workspace.permission_dirname}#{@object.path}"
      end

      def file_path
        "#{base_path}#{StoreAgent.config.permission_extension}"
      end

      private

      def permission_defined_user_identifier(permission_name)
        current_user.identifiers.reverse.find do |identifier|
          user_permission = data["users"][identifier]
          user_permission && user_permission.key?(permission_name)
        end
      end

      def initial_data
        user_permission = @object.initial_permission
        if !(current_user.super_user? || current_user.guest?)
          user_permission[current_user.identifier] = StoreAgent.config.default_owner_permission
        end
        {
          "users" => user_permission,
          "guest" => StoreAgent.config.default_guest_permission
        }
      end
    end
  end
end
