module StoreAgent
  module_function

  def configure
    yield config
  end

  def config
    @config ||= StoreAgent::Configuration.new
  end

  def reserved_filenames
    config.reserved_filenames | config.version_manager.reserved_filenames
  end

  class Configuration
    attr_accessor :storage_root
    attr_accessor :storage_dirname
    attr_accessor :metadata_dirname
    attr_accessor :permission_dirname
    attr_accessor :metadata_extension
    attr_accessor :permission_extension
    attr_accessor :superuser_identifier
    attr_accessor :guest_identifier
    attr_accessor :version_manager
    attr_accessor :reserved_filenames
    attr_accessor :lock_timeout
    attr_accessor :default_directory_bytesize_limit
    attr_accessor :json_indent_level
    attr_accessor :super_user_permission
    attr_accessor :default_owner_permission
    attr_accessor :default_guest_permission

    def initialize
      @storage_root = "/tmp/store_agent"
      @storage_dirname = "/storage"
      @metadata_dirname = "/metadata"
      @permission_dirname = "/permission"
      @metadata_extension = ".meta"
      @permission_extension = ".perm"
      @superuser_identifier = "root"
      @guest_identifier = "nobody"
      @version_manager = StoreAgent::VersionManager
      @reserved_filenames = %w(. ..)
      @lock_timeout = 0.1
      @default_directory_bytesize_limit = 2 ** 30
      @super_user_permission = {
        "read" => true,
        "write" => true,
        "execute" => true
      }
      @default_owner_permission = {
        "read" => true,
        "write" => true,
        "execute" => true
      }
      @default_guest_permission = {}
    end
  end
end
