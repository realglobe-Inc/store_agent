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

      def read(*)
        be_present!
        super
      end

      def update(*)
        be_present!
        super
      end

      def delete(*)
        be_present!
        be_not_root!
        super
      end

      protected

      def be_present!
        if !exists?
          raise StoreAgent::PathError, "object not found: #{path}"
        end
      end

      def be_absent!
        if exists?
          raise StoreAgent::PathError, "object already exists: #{path}"
        end
      end

      def be_not_root!
        if root?
          raise StoreAgent::PathError, "can't delete root node"
        end
      end

      def be_not_reserved!
        basename = File.basename(path)
        reserved_extensions = [] <<
          StoreAgent.config.metadata_extension <<
          StoreAgent.config.permission_extension
        reserved_extensions.each do |extension|
          if basename.end_with?(extension)
            raise StoreAgent::PathError, "extension '#{extension}' is reserved"
          end
        end
        if StoreAgent.config.version_manager.reserved_filenames.include?(basename)
          raise StoreAgent::PathError, "filename '#{basename}' is reserved"
        end
      end
    end
  end
end
