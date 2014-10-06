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

      def read
        super do
          open(storage_object_path) do |f|
            f.read
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
