module StoreAgent
  module Node
    class Attachment
      extend Forwardable
      include StoreAgent::Validator

      attr_reader :object
      def_delegators :object, *%w(current_user root? directory?)

      def initialize(object: nil)
        @object = object
        validates_to_be_not_nil_value!(:object)
      end

      def data
        @data ||= (load || initial_data)
      end

      def create
        dirname = File.dirname(file_path)
        if !File.exists?(dirname)
          FileUtils.mkdir(dirname)
        end
        save
      end

      def delete
        if object.directory?
          FileUtils.remove_dir(File.dirname(file_path))
        else
          FileUtils.rm(file_path)
        end
        object.workspace.version_manager.remove(file_path)
      end

      def save
        json_data = Oj.dump(data, mode: :compat, indent: StoreAgent.config.json_indent_level)
        encoded_data = StoreAgent.config.attachment_data_encoders.inject(json_data) do |data, encoder|
          encoder.encode(data)
        end
        open(file_path, File::WRONLY | File::CREAT) do |f|
          f.truncate(0)
          f.write encoded_data
        end
        object.workspace.version_manager.add(file_path)
        reload
      end

      def load
        if File.exists?(file_path)
          encoded_data = open(file_path, "rb").read
          json_data = StoreAgent.config.attachment_data_encoders.reverse.inject(encoded_data) do |data, encoder|
            encoder.decode(data)
          end
          Oj.load(json_data)
        end
      end

      def reload
        @data = nil
        self
      end

      def inspect
        Oj.dump(data, mode: :compat, indent: 2)
      end
    end
  end
end
