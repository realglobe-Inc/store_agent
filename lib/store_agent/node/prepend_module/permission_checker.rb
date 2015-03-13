module StoreAgent
  module Node
    # オブジェクトの操作時に権限があるかどうかをチェックするモジュール
    module PermissionChecker
      def create(*)
        if !root?
          parent_directory.authorize!("write")
        end
        super
      end

      def read(*)
        authorize!("read")
        super
      end

      def update(*)
        authorize!("write")
        super
      end

      def delete(*)
        authorize!("write")
        super
      end

      def touch(*)
        authorize!("read")
        super
      end

      # TODO
      # コピー先のwrite権限をチェックする
      def copy(dest_path = nil, *)
        authorize!("read")
        super
      end

      # TODO
      # コピー先のwrite権限をチェックする
      def move(dest_path = nil, *)
        authorize!("write")
        super
      end

      def get_metadata(*) # :nodoc:
        authorize!("read")
        super
      end

      def get_permissions(*) # :nodoc:
        authorize!("read")
        super
      end

      def chown(*)
        authorize!("chown")
        super
      end

      def set_permission(*)
        authorize!("chmod")
        super
      end

      def unset_permission(*)
        authorize!("chmod")
        super
      end

      protected

      def authorize!(permission_name)
        if !permission.allow?(permission_name)
          raise StoreAgent::PermissionDeniedError.new(object: self, permission: permission_name)
        end
      end
    end
  end
end
