module StoreAgent
  module Node
    # オブジェクトの権限情報
    class Permission < Attachment
      # オブジェクトに対して、引数で受け取った権限を持つなら true を返す
      def allow?(permission_name)
        case
        when current_user.super_user?
          true
        when !(permission_value = get_permission_value(permission_name)).nil?
          permission_value
        else
          !!data["guest"][permission_name]
        end
      end

      # 権限を設定する
      def set!(identifier: nil, permission_values: {})
        return if permission_values.empty?
        user_permission = [identifier].flatten.inject(data["users"]) do |r, id|
          r[id] ||= {}
        end
        permission_values.each do |permission_name, value|
          user_permission[permission_name] = value
        end
        save
      end

      # 権限を解除する
      def unset!(identifier: nil, permission_names: [])
        identifiers = [identifier].flatten
        permission_names = [permission_names].flatten
        user_permission = find_permission(data["users"], identifiers)
        if user_permission
          user_permission.delete_if do |permission_name, _|
            permission_names.include?(permission_name)
          end
          sweep_permission(data["users"], identifiers)
          save
        end
      end

      def base_path # :nodoc:
        "#{@object.workspace.permission_dirname}#{@object.path}"
      end

      # オブジェクトの権限情報を保存しているファイルの絶対パス
      def file_path
        "#{base_path}#{StoreAgent.config.permission_extension}"
      end

      private

      def find_permission(data, identifiers)
        identifier = identifiers.first
        next_data = data[identifier]
        next_identifiers = identifiers[1..-1]
        case
        when next_identifiers.empty?
          next_data
        when next_data
          find_permission(next_data, next_identifiers)
        else
          nil
        end
      end

      def sweep_permission(data, identifiers)
        identifier = identifiers.first
        next_data = data[identifier]
        if next_data
          sweep_permission(next_data, identifiers[1..-1])
          if next_data.empty?
            data.delete(identifier)
          end
        end
      end

      def get_permission_value(permission_name)
        current_user.identifiers.reverse.each do |identifier|
          user_permission = [identifier].flatten.inject(data["users"]) do |r, id|
            r[id] || break
          end
          if user_permission && user_permission.key?(permission_name)
            return user_permission[permission_name]
          end
        end
        nil
      end

      def initial_data
        user_permission = {}
        if !(current_user.super_user? || current_user.guest?)
          user_permission = current_user.identifier_array.reverse.inject(@object.initial_permission) do |r, id|
            {id => r}
          end
        end
        {
          "users" => user_permission,
          "guest" => StoreAgent.config.default_guest_permission
        }
      end
    end
  end
end
