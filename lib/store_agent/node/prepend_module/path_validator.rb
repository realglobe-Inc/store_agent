module StoreAgent
  module Node
    module PathValidator
      def create(*)
        if !root?
          parent_directory.be_present!
        end
        be_absent!
        be_not_reserved!
        super
      end

      def read(*, revision: nil)
        if revision.nil?
          be_present!
        end
        be_not_reserved!
        super
      end

      def update(*)
        be_present!
        be_not_reserved!
        super
      end

      def delete(*)
        be_present!
        be_not_root!
        be_not_reserved!
        super
      end

      def touch(*)
        be_present!
        be_not_reserved!
        super
      end

      # TODO
      def copy(dest_path = nil, *)
        be_present!
        be_not_reserved!
        super
      end

      # TODO
      def move(dest_path = nil, *)
        be_present!
        be_not_root!
        be_not_reserved!
        super
      end

      def get_metadata(*)
        be_present!
        be_not_reserved!
        super
      end

      def get_permissions(*)
        be_present!
        be_not_reserved!
        super
      end

      def chown(*)
        be_present!
        be_not_reserved!
        super
      end

      def set_permission(*)
        be_present!
        be_not_reserved!
        super
      end

      def unset_permission(*)
        be_present!
        be_not_reserved!
        super
      end

      protected

      def be_present!
        if !exists?
          raise StoreAgent::InvalidPathError, "object not found: #{path}"
        end
      end

      def be_absent!
        if exists?
          raise StoreAgent::InvalidPathError, "object already exists: #{path}"
        end
      end

      def be_not_root!
        if root?
          raise StoreAgent::InvalidPathError, "can't delete root node"
        end
      end

      def be_not_reserved!
        basename = File.basename(path)
        reserved_extensions = [] <<
          StoreAgent.config.metadata_extension <<
          StoreAgent.config.permission_extension
        reserved_extensions.each do |extension|
          if basename.end_with?(extension)
            raise StoreAgent::InvalidPathError, "extension '#{extension}' is reserved"
          end
        end
        if StoreAgent.reserved_filenames.include?(basename)
          raise StoreAgent::InvalidPathError, "filename '#{basename}' is reserved"
        end
      end
    end
  end
end
