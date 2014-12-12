module StoreAgent
  class Workspace
    extend Forwardable
    include StoreAgent::Validator

    attr_reader :current_user, :namespace, :version_manager
    def_delegators :root, *%w(find_object directory file exists?)

    def initialize(current_user: nil, namespace: nil)
      @current_user = current_user
      @namespace = namespace
      validates_to_be_not_nil_value!(:current_user)
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
      @root ||= StoreAgent::Node::DirectoryObject.new(workspace: self, path: "/")
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

    def self.name_list
      if !File.exists?(StoreAgent.config.storage_root)
        FileUtils.mkdir(StoreAgent.config.storage_root)
      end
      FileUtils.cd(StoreAgent.config.storage_root) do
        return Dir.glob("*", File::FNM_DOTMATCH) - StoreAgent.reserved_filenames
      end
    end
  end
end
