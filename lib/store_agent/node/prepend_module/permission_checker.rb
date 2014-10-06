module StoreAgent
  module Node
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

      protected

      def authorize!(permission_name)
        if !permission.allow?(permission_name)
          raise StoreAgent::PermissionDeniedError.new(object: self, permission: permission_name)
        end
      end
    end
  end
end
