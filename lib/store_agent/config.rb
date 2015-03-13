module StoreAgent
  module_function

  # 設定を変更するメソッド
  #   StoreAgent.configure do |c|
  #     c.storage_root = "/path/to/storage/root"
  #     c.version_manager = StoreAgent::VersionManager::RuggedGit
  #   end
  # 変更可能な項目は config メソッドを参照
  def configure
    yield config
  end

  # 設定を参照するメソッド
  #   c = StoreAgent.config # => #<StoreAgent::Configuration:...>
  #   c.storage_root        # => "/path/to/storage/root"
  #   c.storage_dirname     # => "/storage"
  # 各設定と初期値は以下
  # [storage_root]
  #   ライブラリがファイルやメタデータを保存するディレクトリのパス。
  #     c.storage_root # => "/tmp/store_agent"
  # [storage_dirname]
  #   ワークスペース内で、ファイルの実体を保存するディレクトリ名。
  #     c.storage_dirname # => "/storage"
  # [metadata_dirname]
  #   ワークスペース内で、ファイルのメタデータを保存するディレクトリ名。
  #     c.metadata_dirname # => "/metadata"
  # [permission_dirname]
  #   ワークスペース内で、ファイルの権限情報を保存するディレクトリ名。
  #     c.permission_dirname # => "/permission"
  # [metadata_extension]
  #   メタデータファイルの拡張子。<br>
  #   名前の末尾がこの拡張子と一致する場合、ファイルやディレクトリは作成できない。
  #     c.metadata_extension # => ".meta"
  # [permission_extension]
  #   権限情報ファイルの拡張子。<br>
  #   名前の末尾がこの拡張子と一致する場合、ファイルやディレクトリは作成できない。
  #     c.permission_extension # => ".perm"
  # [superuser_identifier]
  #   スーパーユーザーのユーザーID。
  #     c.superuser_identifier # => "root"
  # [guest_identifier]
  #   ゲストユーザーのユーザーID。
  #     c.guest_identifier # => "nobody"
  # [version_manager]
  #   バージョン管理に使用するクラスの名前。
  #     c.version_manager # => StoreAgent::VersionManager
  # [storage_data_encoders]
  #   ファイルの実体をエンコードするのに使用するインスタンスの配列。<br>
  #   配列が複数要素を含む場合、各インスタンスのencode/decodeメソッドが順に呼ばれる。
  #     c.storage_data_encoders # => []
  # [attachment_data_encoders]
  #   ファイルのメタデータ/権限情報をエンコードするのに使用するインスタンスの配列。<br>
  #   配列が複数要素を含む場合、各インスタンスのencode/decodeメソッドが順に呼ばれる。
  #     c.attachment_data_encoders # => []
  # [reserved_filenames]
  #   システムが予約しているファイル名の配列。<br>
  #   名前が含まれている場合、ファイルやディレクトリは作成できない。
  #     c.reserved_filenames # => [".", ".."]
  # [lock_timeout]
  #   ファイル読み書き時のロックのタイムアウト秒数。
  #     c.lock_timeout # => 0.1
  # [default_directory_bytesize_limit]
  #   現在のバージョンでは使用していない。
  # [json_indent_level]
  #   メタデータ/権限情報をJSON形式で保存する際、半角スペース何個でインデントするかの指定。
  #     c.json_indent_level # => 2
  # [default_owner_permission]
  #   ファイルやディレクトリの作成者にデフォルトで付与される権限。<br>
  #   現在のバージョンでは read、write、chown、chmod の4種類が権限として使用できる。
  #     c.default_owner_permission
  #     # =>
  #     # {
  #     #   "read" => true,
  #     #   "write" => true,
  #     #   "execute" => true
  #     # }
  # [default_guest_permission]
  #   権限情報が登録されていないユーザーやゲストユーザーに対して付与される権限。
  #     c.default_guest_permission # => {}
  def config
    @config ||= StoreAgent::Configuration.new
  end

  def reserved_filenames # :nodoc:
    config.reserved_filenames | config.version_manager.reserved_filenames
  end

  # 設定を保持するためのクラス<br>
  # 設定可能な項目は、StoreAgent.config を参照
  class Configuration
    # :enddoc:
    attr_accessor :storage_root
    attr_accessor :storage_dirname
    attr_accessor :metadata_dirname
    attr_accessor :permission_dirname
    attr_accessor :metadata_extension
    attr_accessor :permission_extension
    attr_accessor :superuser_identifier
    attr_accessor :guest_identifier
    attr_accessor :version_manager
    attr_accessor :storage_data_encoders
    attr_accessor :attachment_data_encoders
    attr_accessor :reserved_filenames
    attr_accessor :lock_timeout
    attr_accessor :default_directory_bytesize_limit
    attr_accessor :json_indent_level
    attr_accessor :default_owner_permission
    attr_accessor :default_guest_permission

    def initialize # :nodoc:
      @storage_root = "/tmp/store_agent"
      @storage_dirname = "/storage"
      @metadata_dirname = "/metadata"
      @permission_dirname = "/permission"
      @metadata_extension = ".meta"
      @permission_extension = ".perm"
      @superuser_identifier = "root"
      @guest_identifier = "nobody"
      @version_manager = StoreAgent::VersionManager
      @storage_data_encoders = []
      @attachment_data_encoders = []
      @reserved_filenames = %w(. ..)
      @lock_timeout = 0.1
      @default_directory_bytesize_limit = 2 ** 30
      @default_owner_permission = {
        "read" => true,
        "write" => true,
        "execute" => true
      }
      @default_guest_permission = {}
    end
  end
end
