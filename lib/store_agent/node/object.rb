module StoreAgent
  module Node
    class Object
      extend Forwardable
      include StoreAgent::Validator
      prepend *[] <<
        StoreAgent::Node::PathValidator <<
        StoreAgent::Node::PermissionChecker <<
        StoreAgent::Node::Locker

      attr_reader :workspace, :path
      def_delegators :workspace, *%w(current_user)

      def initialize(workspace: nil, path: "/")
        @workspace = workspace
        validates_to_be_not_nil_value!(:workspace)
        @path = sanitize_path(path)
      end

      def metadata
        @metadata ||= StoreAgent::Node::Metadata.new(object: self)
      end

      def permission
        @permission ||= StoreAgent::Node::Permission.new(object: self)
      end

      def initial_owner
        @initial_owner ||= current_user.identifier
      end

      def initial_owner=(owner_identifier)
        authorize!("chown")
        @initial_owner = owner_identifier
      end

      def initial_permission
        @initial_permission ||= StoreAgent.config.default_owner_permission
      end

      def initial_permission=(permissions)
        authorize!("chmod")
        @initial_permission = permissions
      end

      def create(*)
        workspace.version_manager.transaction("created #{path}") do
          yield
          metadata.create
          permission.create
        end
        self
      end

      def read(*)
        yield
      end

      def update(*)
        workspace.version_manager.transaction("updated #{path}") do
          yield
        end
        true
      end

      def delete(*)
        workspace.version_manager.transaction("deleted #{path}") do
          yield
          metadata.delete
          permission.delete
        end
        true
      end

      def touch(*)
        workspace.version_manager.transaction("touch #{path}") do
          yield
          metadata.updated_at = Time.now
          metadata.save
          workspace.version_manager.add(permission.file_path)
        end
      end

      def copy(dest_path = nil)
        workspace.version_manager.transaction("copy #{path} to #{dest_path}") do
          yield
        end
      end

      def move(dest_path = nil)
        workspace.version_manager.transaction("move #{path} to #{dest_path}") do
          yield
        end
      end

      def get_metadata(*)
        yield
        metadata.data
      end

      def get_permissions(*)
        yield
        permission.data
      end

      def chown(*, identifier: nil, **_)
        workspace.version_manager.transaction("change_owner #{path}") do
          yield
          metadata.owner = identifier
          metadata.save
        end
      end

      def set_permission(identifier: nil, permission_values: {}, **_)
        workspace.version_manager.transaction("add_permission #{path}") do
          permission.set!(identifier: identifier, permission_values: permission_values)
          yield
        end
      end

      def unset_permission(identifier: nil, permission_names: [], **_)
        workspace.version_manager.transaction("remove_permission #{path}") do
          permission.unset!(identifier: identifier, permission_names: permission_names)
          yield
        end
      end

      def parent_directory
        if !root?
          @parent_directory ||= StoreAgent::Node::DirectoryObject.new(workspace: @workspace, path: File.dirname(@path))
        end
      end

      def revisions
        workspace.version_manager.revisions("storage#{path}")
      end

      def exists?
        File.exists?(storage_object_path)
      end

      def filetype
        File.ftype(storage_object_path)
      end

      def initial_metadata
        @initial_metadata ||= {}
      end

      def default_metadata
        {
          "size" => StoreAgent::Node::Metadata.datasize_format(initial_bytesize),
          "bytes" => initial_bytesize,
          "owner" => initial_owner,
          "is_dir" => directory?,
          "created_at" => updated_at.to_s,
          "updated_at" => updated_at.to_s,
          "created_at_unix_timestamp" => updated_at.to_i,
          "updated_at_unix_timestamp" => updated_at.to_i,
        }.merge(initial_metadata)
      end

      def root?
        @path == "/"
      end

      def directory?
        false
      end

      def file?
        false
      end

      def storage_object_path
        "#{@workspace.storage_dirname}#{@path}"
      end

      private

      def sanitize_path(path)
        File.absolute_path("/./#{path}")
      end

      def owner?
        metadata["owner"] == current_user.identifier
      end

      def initial_bytesize
        0
      end

      def updated_at
        File.mtime(storage_object_path)
      end
    end
  end
end
