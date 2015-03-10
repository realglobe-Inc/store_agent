module StoreAgent
  module Node
    class Metadata < Attachment
      def_delegators :data, *%w([] []=)

      def create
        super
        parent.update(disk_usage: disk_usage, directory_file_count: 1, tree_file_count: 1, recursive: true)
      end

      def update(disk_usage: 0, directory_file_count: 0, tree_file_count: 0, recursive: false)
        if directory?
          self["directory_file_count"] += directory_file_count
          self["tree_file_count"] += tree_file_count
        end
        self.disk_usage += disk_usage
        save
        if recursive
          parent.update(disk_usage: disk_usage, tree_file_count: tree_file_count, recursive: recursive)
        end
      end

      def delete
        parent.update(disk_usage: -disk_usage, directory_file_count: -1, tree_file_count: -1, recursive: true)
        super
      end

      def base_path
        "#{@object.workspace.metadata_dirname}#{@object.path}"
      end

      def file_path
        "#{base_path}#{StoreAgent.config.metadata_extension}"
      end

      def self.datasize_format(size)
        byte_names = %w(KB MB GB TB PB)
        byte_length = size.abs.to_s(2).length
        if byte_length <= 10
          "#{size} bytes"
        else
          exponent = [byte_names.length, (byte_length - 1) / 10].min
          sprintf("%0.2f%s", size.to_f / (2 ** (10 * exponent)), byte_names[exponent - 1])
        end
      end

      def disk_usage
        if directory?
          self["directory_bytes"]
        else
          self["bytes"]
        end
      end

      def disk_usage=(usage)
        usage_string = StoreAgent::Node::Metadata.datasize_format(usage)
        if directory?
          self["directory_size"] = usage_string
          self["directory_bytes"] = usage
        else
          self["size"] = usage_string
          self["bytes"] = usage
        end
      end

      def owner=(identifier)
        self["owner"] = identifier
      end

      def updated_at=(time)
        self["updated_at"] = time.to_s
        self["updated_at_unix_timestamp"] = time.to_i
      end

      private

      def parent
        if root?
          SuperRootMetadata.new
        else
          object.parent_directory.metadata
        end
      end

      def initial_data
        object.default_metadata
      end

      class SuperRootMetadata < Metadata
        def initialize(*)
        end

        def update(*)
        end
      end
    end
  end
end
