module StoreAgent
  module Node
    class Attachment
      attr_reader :object

      def initialize(params)
        @object = params["object"] || params[:object]
        if @object.nil?
          raise ArgumentError, "object is required"
        end
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

      def save
        open(file_path, "w") do |f|
          f.write Oj.dump(data, mode: :compat, indent: StoreAgent.config.json_indent_level)
        end
      end

      def load
        File.exists?(file_path) && Oj.load_file(file_path)
      end

      def reload
        @data = load
        self
      end
    end
  end
end
