module StoreAgent
  module Node
    class FileObject < Object
      attr_writer :body

      def create(*params, &block)
        set_body(*params, &block)
        super do
          save
        end
      end

      def read
        super
        open(storage_object_path) do |f|
          f.read
        end
      end

      def update(*params, &block)
        super
        set_body(*params, &block)
        if @body.nil?
          raise "file body required"
        end
        disk_usage_diff = @body.length - disk_usage
        self.disk_usage = @body.length
        metadata.save
        update_parent_directory_metadata("disk_usage" => disk_usage_diff, "file_count" => 0)
        save
      end

      def delete
        super
        metadata.reload
        update_parent_directory_metadata("disk_usage" => -disk_usage, "file_count" => -1)
        FileUtils.rm([storage_object_path, metadata.file_path, permission.file_path])
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
        when options.is_a?(Hash)
          @body = options["body"] || options[:body]
        end
      end
    end
  end
end
