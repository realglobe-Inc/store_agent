module StoreAgent
  module Node
    class Metadata < Attachment
      def [](key)
        data[key]
      end

      def []=(key, value)
        data[key] = value
      end

      def file_path
        "#{@object.workspace.metadata_dirname}#{@object.path}#{StoreAgent.config.metadata_extension}"
      end

      private

      def initial_data
        object.initial_metadata
      end
    end
  end
end
