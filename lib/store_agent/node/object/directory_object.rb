module StoreAgent
  module Node
    class DirectoryObject < Object
      def initialize(params)
        super
        if !@path.end_with?("/")
          @path = "#{@path}/"
        end
      end

      def create
        super do
          FileUtils.mkdir(storage_object_path)
          workspace.version_manager.add("#{storage_object_path}.keep")
        end
      end

      # TODO
      def read(revision: nil)
        super do
          filenames =
            if revision.nil?
              current_children_filenames
            else
              workspace.version_manager.read(path: storage_object_path, revision: revision)
            end
          filenames - StoreAgent.reserved_filenames
        end
      end

      def update
        raise "cannot update directory"
      end

      def delete(*)
        super do
          success, errors = call_for_children do |child|
            child.delete(recursive: false)
          end
          if success
            FileUtils.remove_dir(storage_object_path)
          else
            raise StoreAgent::PermissionDeniedError.new(errors: errors)
          end
          workspace.version_manager.remove("#{storage_object_path}.keep")
        end
      end

      def touch(*, recursive: false)
        super do
          FileUtils.touch("#{storage_object_path}.keep")
          workspace.version_manager.add("#{storage_object_path}.keep")
          if recursive
            success, errors = call_for_children do |child|
              child.touch(recursive: true)
            end
          end
        end
      end

      def copy(dest_path = nil, *)
        super do
          dest_directory = build_dest_directory(dest_path).create
          success, errors = call_for_children do |child|
            child.copy("#{dest_directory.path}#{File.basename(child.path)}")
          end
        end
      end

      def move(dest_path = nil, *)
        super do
          dest_directory = build_dest_directory(dest_path)
          disk_usage = metadata.disk_usage
          file_count = directory_file_count
          %w(storage_dirname metadata_dirname permission_dirname).each do |method_name|
            src = "#{workspace.send(method_name)}#{path}"
            dest = "#{workspace.send(method_name)}#{dest_directory.path}"
            FileUtils.mv(src, dest)
          end
          dest_directory.touch(recursive: true)
          dest_directory.parent_directory.metadata.update(disk_usage: disk_usage, directory_file_count: 1, tree_file_count: file_count + 1, recursive: true)
          parent_directory.metadata.update(disk_usage: -disk_usage, directory_file_count: -1, tree_file_count: -(file_count + 1), recursive: true)
        end
      end

      def get_metadata(*)
        super do
        end
      end

      def get_permissions(*)
        super do
        end
      end

      def chown(*, identifier: nil, recursive: false)
        super do
          if recursive
            success, errors = call_for_children do |child|
              child.chown(identifier: identifier, recursive: recursive)
            end
          end
        end
      end

      def set_permission(identifier: nil, permission_values: {}, recursive: false)
        super do
          if recursive
            success, errors = call_for_children do |child|
              child.set_permission(identifier: identifier, permission_values: permission_values)
            end
          end
        end
      end

      def unset_permission(identifier: nil, permission_names: [], recursive: false)
        super do
          if recursive
            success, errors = call_for_children do |child|
              child.unset_permission(identifier: identifier, permission_names: permission_names)
            end
          end
        end
      end

      def find_object(path)
        object = StoreAgent::Node::Object.new(workspace: workspace, path: namespaced_absolute_path(path))
        case object.exists? && object.filetype
        when false
          raise "no such object"
        when "directory"
          directory(path)
        when "file"
          file(path)
        end
      end

      def directory(path)
        StoreAgent::Node::DirectoryObject.new(workspace: workspace, path: namespaced_absolute_path(path))
      end

      def file(path)
        StoreAgent::Node::FileObject.new(workspace: workspace, path: namespaced_absolute_path(path))
      end

      def children
        (current_children_filenames - StoreAgent.reserved_filenames).map{|filename|
          find_object(filename)
        }
      end

      def initial_metadata
        super.merge(directory_metadata)
      end

      def directory_metadata
        {
          "is_dir" => true,
          "directory_size" => StoreAgent::Node::Metadata.datasize_format(bytesize),
          "directory_bytes" => bytesize,
          "directory_size_limit" => StoreAgent::Node::Metadata.datasize_format(StoreAgent.config.default_directory_bytesize_limit),
          "directory_bytes_limit" => StoreAgent.config.default_directory_bytesize_limit,
          "directory_file_count" => 0,
          "tree_file_count" => 0
        }
      end

      def directory_file_count
        metadata["directory_file_count"]
      end

      def tree_file_count
        metadata["tree_file_count"]
      end

      def directory?
        true
      end

      private

      def namespaced_absolute_path(path)
        "#{@path}#{sanitize_path(path)}"
      end

      def build_dest_directory(dest_path)
        dest_directory = workspace.directory(dest_path)
        if dest_directory.exists?
          dest_directory.directory(File.basename(path))
        else
          dest_directory
        end
      end

      def current_children_filenames
        FileUtils.cd(storage_object_path) do
          return Dir.glob("*", File::FNM_DOTMATCH)
        end
      end

      def call_for_children
        errors = []
        children.each do |child|
          begin
            yield child
          rescue StoreAgent::PermissionDeniedError => e
            errors << e
          end
        end
        return errors.empty?, errors
      end
    end
  end
end
