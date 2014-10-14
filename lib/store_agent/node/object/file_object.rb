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
            open(storage_object_path) do |f|
              f.read
            end
          else
            workspace.version_manager.read(path: storage_object_path, revision: revision)
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
          metadata.update(disk_usage: @body.length - metadata.disk_usage, recursive: true)
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

      # TODO
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

      # TODO
      def move(dest_path = nil, *)
        super do
          copy(dest_path)
          delete
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
        open(storage_object_path, "w") do |f|
          f.write @body
        end
        workspace.version_manager.add(storage_object_path)
      end

      def children
        []
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
