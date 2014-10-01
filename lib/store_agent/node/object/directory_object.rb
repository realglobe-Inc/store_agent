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
        end
      end

      def read
        File.glob("*")
      end

      def update
        raise "cannot update directory"
      end

      # TODO check permission
      def delete
        super
        errors = []
        children.each do |child|
          begin
            child.delete
          rescue => e
            errors << e
          end
        end
        if errors.empty?
          delete_node
        else
          raise errors.inspect
        end
      end

      def delete_node
        metadata.reload
        update_parent_directory_metadata("disk_usage" => -disk_usage, "file_count" => -1)
        [storage_object_path, File.dirname(metadata.file_path), File.dirname(permission.file_path)].each do |path|
          FileUtils.remove_dir(path)
        end
      end
      private :delete_node

      # TODO mv directory

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
        node_names = []
        FileUtils.cd(storage_object_path) do
          node_names = Dir.glob("*", File::FNM_DOTMATCH)
        end
        node_names = node_names - StoreAgent.config.reject_filenames
        node_names.map{|filename|
          find_object(filename)
        }
      end

      def initial_metadata
        super.merge(directory_metadata)
      end

      def directory_metadata
        {
          "is_dir" => true,
          "directory_size" => to_datasize_format(bytesize),
          "directory_bytes" => bytesize,
          "directory_size_limit" => to_datasize_format(StoreAgent.config.default_directory_bytesize_limit),
          "directory_bytes_limit" => StoreAgent.config.default_directory_bytesize_limit,
          "directory_file_count" => 0,
          "directory_tree_file_count" => 0
        }
      end

      def disk_usage
        metadata["directory_bytes"]
      end

      def disk_usage=(usage)
        metadata["directory_size"] = to_datasize_format(usage)
        metadata["directory_bytes"] = usage
      end

      def directory_file_count
        metadata["directory_file_count"]
      end

      def directory_file_count=(count)
        metadata["directory_file_count"] = count
      end

      def directory_tree_file_count
        metadata["directory_tree_file_count"]
      end

      def directory_tree_file_count=(count)
        metadata["directory_tree_file_count"] = count
      end

      def directory?
        true
      end

      private

      def namespaced_absolute_path(path)
        "#{@path}#{sanitize_path(path)}"
      end
    end
  end
end
