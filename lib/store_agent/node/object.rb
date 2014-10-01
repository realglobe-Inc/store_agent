module StoreAgent
  module Node
    class Object
      attr_reader :workspace, :path

      def initialize(params)
        %w(workspace path).each do |attribute|
          value = params[attribute] || params[attribute.to_sym]
          instance_variable_set("@#{attribute}", value)
        end
        if @workspace.nil?
          raise ArgumentError, "workspace is required"
        end
        @path = sanitize_path(@path)
      end

      def create(*params, &block)
        StoreAgent::Validator.validates_to_be_absent_object!(self)
        if !root?
          StoreAgent::Validator.validates_to_be_present_object!(parent_directory)
        end
        validate_object_name!
        if parent_directory && !parent_directory.permission.allow?("write")
          # TODO error message
          raise
        end
        if block_given?
          yield self
        end
        metadata.create
        permission.create
        update_parent_directory_metadata("disk_usage" => disk_usage, "file_count" => 1)
        # TODO rescue and rollback
        self
      end

      def read
        StoreAgent::Validator.validates_to_be_present_object!(self)
        validate_permission!("read")
      end

      def update(*params, &block)
        StoreAgent::Validator.validates_to_be_present_object!(self)
        validate_permission!("write")
      end

      def delete
        validate_permission!("write")
      end

      def user
        @workspace.user
      end

      def parent_directory
        if !root?
          @parent_directory ||= StoreAgent::Node::DirectoryObject.new(workspace: @workspace, path: File.dirname(@path))
        end
      end

      def update_parent_directory_metadata(params)
        if root?
          return
        end
        parent_directory.directory_file_count = parent_directory.directory_file_count + params["file_count"]
        parent_directory.update_ancestor_directory_metadata(params)
      end

      def update_ancestor_directory_metadata(params)
        self.disk_usage = disk_usage + params["disk_usage"]
        self.directory_tree_file_count = directory_tree_file_count + params["file_count"]
        metadata.save
        if parent_directory
          parent_directory.update_ancestor_directory_metadata(params)
        end
      end

      def exists?
        File.exists?(storage_object_path)
      end

      def filetype
        File.ftype(storage_object_path)
      end

      def metadata
        @metadata ||= StoreAgent::Node::Metadata.new(object: self)
      end

      def permission
        @permission ||= StoreAgent::Node::Permission.new(object: self)
      end

      def initial_metadata
        {
          "size" => to_datasize_format(bytesize),
          "bytes" => bytesize,
          "owner" => user.identifier,
          "is_dir" => directory?,
          "created_at" => updated_at.to_s,
          "updated_at" => updated_at.to_s,
          "created_at_unix_timestamp" => updated_at.to_i,
          "updated_at_unix_timestamp" => updated_at.to_i,
        }
      end

      def validate_permission!(action)
        if !permission.allow?(action)
          raise "permission denied: #{action} to #{@path}"
        end
      end
      private :validate_permission!

      def disk_usage
        metadata["bytes"]
      end

      def disk_usage=(usage)
        metadata["size"] = to_datasize_format(usage)
        metadata["bytes"] = usage
      end

      def root?
        @path == "/"
      end

      def directory?
        false
      end

      private

      def validate_object_name!
        if File.basename(@path).end_with?(StoreAgent.config.metadata_extension)
          raise "invalid name"
        end
      end

      def sanitize_path(path)
        File.absolute_path("/./#{path}")
      end

      def owner?
        metadata["owner"] == user.identifier
      end

      def storage_object_path
        "#{@workspace.storage_dirname}#{@path}"
      end

      def to_datasize_format(size)
        byte_names = %w(KB MB GB TB PB)
        byte_length = size.abs.to_s(2).length
        if byte_length <= 10
          "#{size} bytes"
        else
          exponent = [byte_names.length, (byte_length - 1) / 10].min
          sprintf("%0.2f%s", size.to_f / (2 ** (10 * exponent)), byte_names[exponent - 1])
        end
      end

      def bytesize
        File.size(storage_object_path)
      end

      def updated_at
        File.mtime(storage_object_path)
      end
    end
  end
end
