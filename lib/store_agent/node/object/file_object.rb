module StoreAgent
  module Node
    class FileObject < Object
      attr_writer :body

      def create(*params, &block)
        super do
          set_body(*params, &block)
          save
        end
      end

      def read(revision: nil)
        super do
          if revision.nil?
            encoded_data = open(storage_object_path) do |f|
              f.read
            end
          else
            encoded_data = workspace.version_manager.read(path: storage_object_path, revision: revision)
          end
          StoreAgent.config.attachment_data_encoders.reverse.inject(encoded_data) do |data, encoder|
            encoder.decode(data)
          end
        end
      end

      def update(*params, &block)
        super do
          set_body(*params, &block)
          if @body.nil?
            raise "file body required"
          end
          save
        end
      end

      def delete(*)
        super do
          FileUtils.rm(storage_object_path)
          workspace.version_manager.remove(storage_object_path)
        end
      end

      def touch(*)
        super do
          FileUtils.touch(storage_object_path)
          workspace.version_manager.add(storage_object_path)
        end
      end

      def copy(dest_path = nil, *)
        super do
          file_body = read
          dest_file = workspace.file(dest_path)
          if dest_file.exists?
            dest_file.update(file_body)
          else
            dest_file.create(read)
          end
        end
      end

      def move(dest_path = nil, *)
        super do
          dest_file = workspace.file(dest_path)
          if dest_file.exists?
            disk_usage_diff = metadata.disk_usage - dest_file.metadata.disk_usage
            file_count = 0
          else
            disk_usage_diff = metadata.disk_usage
            file_count = 1
          end
          FileUtils.mv(storage_object_path, dest_file.storage_object_path)
          FileUtils.mv(metadata.file_path, dest_file.metadata.file_path)
          FileUtils.mv(permission.file_path, dest_file.permission.file_path)
          dest_file.touch
          dest_file.parent_directory.metadata.update(disk_usage: disk_usage_diff, directory_file_count: file_count, tree_file_count: file_count, recursive: true)
          parent_directory.metadata.update(disk_usage: -dest_file.metadata.disk_usage, directory_file_count: -1, tree_file_count: -1, recursive: true)
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

      def chown(*)
        super do
        end
      end

      def set_permission(*)
        super do
        end
      end

      def unset_permission(*)
        super do
        end
      end

      def find_object(path)
        raise "#{@path} is not directory"
      end

      def directory(path)
        raise "#{@path} is not directory"
      end

      def file(path)
        raise "#{@path} is not directory"
      end

      def save
        encoded_data = StoreAgent.config.storage_data_encoders.inject(@body) do |data, encoder|
          encoder.encode(data)
        end
        open(storage_object_path, "w") do |f|
          f.write encoded_data
        end
        disk_usage_diff = (@body || "").length - metadata.disk_usage
        metadata.update(disk_usage: disk_usage_diff, recursive: true)
        workspace.version_manager.add(storage_object_path)
      end

      def children
        []
      end

      def file?
        true
      end

      private

      def set_body(*params)
        case
        when block_given?
          yield self
        when (options = params.first).is_a?(String)
          @body = options
        when options.is_a?(Symbol)
          @body = options.to_s
        when options.is_a?(Hash)
          @body = options["body"] || options[:body]
        end
      end
    end
  end
end
