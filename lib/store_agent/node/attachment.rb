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
        open(file_path, File::WRONLY | File::CREAT) do |f|
          f.truncate(0)
          f.write Oj.dump(data, mode: :compat, indent: StoreAgent.config.json_indent_level)
        end
        object.workspace.version_manager.add(file_path)
      end

      def load
        File.exists?(file_path) && Oj.load_file(file_path)
      end

      def reload
        @data = load
        self
      end

      def inspect
        Oj.dump(data, mode: :compat, indent: 2)
      end
    end
  end
end
