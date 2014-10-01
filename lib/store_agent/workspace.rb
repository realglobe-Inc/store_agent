module StoreAgent
  class Workspace
    attr_reader :user, :namespace

    def initialize(params)
      %w(user namespace).each do |attribute|
        value = params[attribute] || params[attribute.to_sym]
        instance_variable_set("@#{attribute}", value)
      end
      if @user.nil?
        raise ArgumentError, "user is required"
      end
      StoreAgent::Validator.validates_to_be_string_or_symbol!(@namespace)
      StoreAgent::Validator.validates_to_be_excluded_slash!(@namespace)
    end

    def create
      if exists?
        raise "workspace #{@namespace} is already exists"
      end
      FileUtils.mkdir_p(namespace_dirname)
      root.create
    end

    def root
      StoreAgent::Node::DirectoryObject.new(workspace: self, path: "/")
    end

    def directory(path)
      root.directory(path)
    end

    def file(path)
      root.file(path)
    end

    def exists?
      root.exists?
    end

    def namespace_dirname
      File.absolute_path("#{StoreAgent.config.storage_root}/#{@namespace}")
    end

    def storage_dirname
      File.absolute_path("#{namespace_dirname}/#{StoreAgent.config.storage_dirname}")
    end

    def metadata_dirname
      File.absolute_path("#{namespace_dirname}/#{StoreAgent.config.metadata_dirname}")
    end

    def permission_dirname
      File.absolute_path("#{namespace_dirname}/#{StoreAgent.config.permission_dirname}")
    end
  end
end
