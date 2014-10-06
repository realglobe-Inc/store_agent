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
        super do
          FileUtils.cd(storage_object_path) do
            return Dir.glob("*")
          end
        end
      end

      def update
        raise "cannot update directory"
      end

      def delete(*)
        super do
          errors = []
          children.each do |child|
            begin
              child.delete(recursive: false)
            rescue StoreAgent::PermissionDeniedError => e
              errors << e
            end
          end
          if errors.empty?
            FileUtils.remove_dir(storage_object_path)
          else
            raise StoreAgent::PermissionDeniedError.new(errors: errors)
          end
        end
      end

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
    end
  end
end
