module StoreAgent
  class Workspace
    include StoreAgent::Validator

    attr_reader :user, :namespace, :version_manager

    def initialize(user: nil, namespace: nil)
      @user = user
      @namespace = namespace
      validates_to_be_not_nil_value!(:user)
      validates_to_be_string_or_symbol!(@namespace)
      validates_to_be_excluded_slash!(@namespace)
      @version_manager = StoreAgent.config.version_manager.new(workspace: self)
    end

    def create
      if exists?
        raise "workspace #{@namespace} is already exists"
      end
      FileUtils.mkdir_p(namespace_dirname)
      @version_manager.init
      root.create
    end

    def delete
      if !exists?
        raise "workspace #{@namespace} not found"
      end
      FileUtils.remove_dir(namespace_dirname)
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
