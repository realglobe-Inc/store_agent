# StoreAgent

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'store_agent'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install store_agent

## Usage

基本的な使用方法は以下。  

### 1. ユーザー

ストレージのデータにアクセスするユーザー。  

```ruby
# 一般ユーザー
user = StoreAgent::User.new("user_xxx")
user = StoreAgent::User.new(:user_yyy) # シンボルは文字列に変換される
# ルートユーザー
root_user = StoreAgent::Superuser.new
# ゲストユーザー
guest_user = StoreAgent::Guest.new
```

一般ユーザーの初期化時には引数としてIDが必要だが、これは可変引数で複数のIDを渡す事もできる。  
その場合、権限チェック時には受け取った引数の後ろから順に権限をチェックし、最初に見つかった権限が適用される。  
ユーザー自身のIDとしては最後の引数が使用され、このIDがオブジェクト作成時のオーナーになる。  

```ruby
# グループに所属する場合など、複数IDを持つユーザー
group_user = StoreAgent::User.new("group_001", "group_002", ..., "user_xxx")
group_user.identifier # => "user_xxx"
```

IDとして文字列ではなく配列を渡すと、ネームスペースで分けられたIDを指定する事ができる。  
権限情報は配列の要素の順にネストして保存され、権限チェックはネームスペースを順に辿って行う。  
ファイルやディレクトリの作成者としては配列の先頭要素が使用される。  

```ruby
# ネームスペース付きのユーザー
namespaced_user = StoreAgent::User.new(["user_xxx", "namespace_001", "namespace_002"])
namespaced_user.identifier # => "user_xxx"
# 権限チェック時には、permission["user_xxx"]["namespace_001"]["namespace_002"] をチェックする
```

### 2. ワークスペース

ストレージ、メタデータ、権限情報を管理する名前空間。  
バージョン管理を使用する場合には、ワークスペースが一つのgitリポジトリになる。  

```ruby
workspace = user.workspace("workspace_01")
workspace.exists? # => false
workspace.create
workspace.exists? # => true
```

### 3. ストレージ

ワークスペースの/storage/以下をストレージ領域として使用する。  
ファイル/ディレクトリ名の命名規則はシステムに準拠するが、それに加えて以下の制限がある。  

* config.reserved_filenamesで設定されている名前は使用できない。
* gitのバージョン管理を使用する場合は、.gitおよび.keepという名前は使用できない。
* メタデータや権限情報と名前の衝突が起きないよう、最後が.metaや.permで終わるような名前は使用できない。

```ruby
# ディレクトリ作成
directory_01 = workspace.directory("foo")
directory_01.path # => "/foo/"
directory_01.exists? # => false
directory_01.create
directory_01.exists? # => true
directory_02 = directory_01.directory("bar")
directory_02.path # => "/foo/bar/"
directory_02.create
workspace.directory("foo/bar").exists? # => true

# ファイル作成
file_01 = workspace.file("hoge.txt")
file_01.path # => "/hoge.txt"
file_01.exists? # => false
file_01.create("hoge")
file_01.exists? # => true
file_01.read # => "hoge"
file_02 = directory_01.file("fuga.txt")
file_02.path # => "/foo/fuga.txt"
file_02.exists? # => false
file_02.create{|f| f.body = "fuga"}
file_02.exists? # => true
file_02.read # => "fuga"
directory_01.read # => ["bar", "fuga.txt"]

# ファイル更新
file_01.update("updated") # => true
file_01.read # => "updated"

# ファイル削除
file_02.delete # => true
file_02.exists? # => false
file_02.update("fuga") # => StoreAgent::PathError
file_02.delete # => StoreAgent::PathError

# ファイル/ディレクトリの移動
file_01.move("move.txt")
directory_01.move("move_dir")
workspace.root.read # => ["move.txt", "move_dir"]

# ファイル/ディレクトリのコピー
workspace.file("move.txt").copy("hoge.txt")
workspace.directory("move_dir").copy("foo")
workspace.root.read # => ["move.txt", "hoge.txt", "move_dir", "foo"]
```

### 4. メタデータ

ストレージと同様の構成で /metadata/ 以下にメタデータ用のファイルが作成される。  
storage/${path} に対応するメタデータは metadata/${path}.meta に保存され、オブジェクトの操作時に更新される。  
例えば、  

* `/` に対応するメタデータは `/.meta`
* `/foo/` に対応するメタデータは `/foo/.meta`
* `/foo/bar.json` に対応するメタデータは `/foo/bar.json.meta`

となる。  
また metadata/${path}.meta.lock という名前でロックファイルも作成され、オブジェクトの操作時にはこのファイルがロックされる。  

```ruby
# メタデータ
workspace.directory("foo").metadata # => {...}
workspace.file("hoge.txt").metadata # => {...}

# オーナー変更
workspace.file("hoge.txt").chown(identifier: "user_yyy")
workspace.file("hoge.txt").metadata # => {...}
workspace.directory("foo").chown(identifier: "user_zzz", recursive: true)
workspace.directory("foo/bar").metadata # => {...}
```

メタデータの形式は以下のようなJSON。  

```json
# オブジェクトがディレクトリの場合
{
  "size": "4.00KB",
  "bytes": 4096,
  "owner": "xxx-xxx-xxx-xxx",
  "is_dir": true,
  "created_at": "YYYY-mm-dd HH:MM:SS Z",
  "updated_at": "YYYY-mm-dd HH:MM:SS Z",
  "created_at_unix_timestamp": 1412345678,
  "updated_at_unix_timestamp": 1412345678,
  "directory_size": "8.00KB",
  "directory_bytes": 8192,
  "directory_size_limit": "1.00GB",
  "directory_bytes_limit": 1073741824,
  "directory_file_count": 1,
  "tree_file_count": 1
}

# オブジェクトがファイルの場合
{
  "size": "10.4KB",
  "bytes": 10634,
  "owner": "xxx-xxx-xxx-xxx",
  "is_dir": false,
  "created_at": "YYYY-mm-dd HH:MM:SS Z",
  "updated_at": "YYYY-mm-dd HH:MM:SS Z",
  "created_at_unix_timestamp": 1412345678,
  "updated_at_unix_timestamp": 1412345678
}
```

### 5. 権限情報

ストレージと同様の構成で /permission/ 以下に権限情報用のファイルが作成される。  
storage/${path} に対応する権限情報は permission/${path}.perm に保存する。  

```ruby
# パーミッション
workspace.directory("foo").permission # => {...}
workspace.file("hoge.txt").permission # => {...}

# パーミッション変更
r_file_01 = root_user.workspace("workspace_01").file("hoge.txt")
r_directory_01 = root_user.workspace("workspace_01").directory("foo")
r_directory_02 = r_directory_01.directory("bar")
r_file_01.set_permission(identifier: "user_yyy", permission_values: {"read" => true, "write" => false})
r_directory_01.set_permission(identifier: "user_yyy", permission_values: {"read" => true})
r_directory_02.set_permission(identifier: "user_yyy", permission_values: {"write" => true}, recursive: true)

# パーミッション解除
r_file_01.unset_permission(identifier: "user_yyy", permission_names: "read")
r_directory_01.unset_permission(identifier: "user_yyy", permission_names: ["read"])
r_directory_02.unset_permission(identifier: "user_yyy", permission_names: ["read", "write"], recursive: true)
```

権限情報の形式は以下のようなJSON。  

```json
{
  "users":{
    "user-xxx-uid":{
      "read":true,
      "write":true,
      "execute":true,
      "chown":true,
      "chmod":true
    },
    "user-yyy-uid":{
      "namespace-zzz":{
        "read":true,
        "write":false
      }
    }
  },
  "guest":{
    "read":true,
    "execute":true
  }
}
```

権限のチェックは以下の順に処理される。  

1. ルートユーザーは全ての権限を持つ。
2. 一般ユーザーの場合、上記のJSONの"users"をユーザーIDで検索する。キーが見つかり、値の中に権限と一致するキーがあればその値が使用される。ユーザーIDが配列の場合、配列の順にこの処理が実行される。
3. ゲストユーザーまたは一般ユーザーだが権限情報が登録されていない場合、上記JSONの"guest"の中に権限と一致するキーがあればその値が使用される。キーが無い場合には権限が無い。

### 6. 設定変更

使用前に、以下のようにして一部の設定を変更する事ができる。  

```ruby
StoreAgent.configure do |c|
  c.storage_root = "path/to/storage/directory"
  c.version_manager = StoreAgent::VersionManager::RuggedGit
  c.storage_data_encoders = [] <<
    StoreAgent::DataEncoder::GzipEncoder.new <<
    StoreAgent::DataEncoder::OpensslAes256CbcEncoder.new
  c.json_indent_level = 2
end
```

変更可能な設定は以下。  
デフォルト値はlib/store_agent/config.rbを参照。  

```ruby
storage_root                      # ファイル/メタデータ/権限情報を保存するディレクトリ
storage_dirname                   # ファイルを保存するディレクトリ名
metadata_dirname                  # メタデータを保存するディレクトリ名
permission_dirname                # 権限情報を保存するディレクトリ名
metadata_extension                # メタデータの拡張子
permission_extension              # 権限情報の拡張子
superuser_identifier              # ルートユーザーのID
guest_identifier                  # ゲストユーザーのID
version_manager                   # バージョン管理に使用するクラス
storage_data_encoders             # ファイルのエンコードに使用するオブジェクトのリスト
attachment_data_encoders          # メタデータおよび権限情報のエンコードに使用するオブジェクトのリスト
reserved_filenames                # システムが予約しているファイル名
lock_timeout                      # ファイルのロック時のタイムアウト秒数
default_directory_bytesize_limit  # 使用していない
default_owner_permission          # ファイル/ディレクトリ作成時に作成者に付与されるデフォルトの権限
default_guest_permission          # ファイル/ディレクトリ作成時にゲストユーザーに付与されるデフォルトの権限
```

### 7. バージョン管理

ワークスペースをgitリポジトリとしてバージョン管理する事ができる。  
デフォルトでは無効になっているので、有効化する場合は別途gemをインストールし、以下のように設定する必要がある。  
使用できるgemは[rugged](https://github.com/libgit2/rugged)、あるいは[ruby-git](https://github.com/schacon/ruby-git)のどちらか。  

```ruby
### ruggedを使用する場合
# Gemfile
gem "rugged"

# 設定変更
StoreAgent.configure do |c|
  c.version_manager = StoreAgent::VersionManager::RuggedGit
end

### ruby-gitを使用する場合
# Gemfile
gem "git"

# 設定変更
StoreAgent.configure do |c|
  c.version_manager = StoreAgent::VersionManager::RubyGit
end
```

過去のバージョンのファイルやディレクトリを読み込む場合は以下のように実行する。  

```ruby
# リビジョン一覧
file_01.revisions # => ["xxxxxx", "yyyyyy", ...]
directory_01.revisions # => ["zzzzzz", ...]

# 過去のバージョンのファイルやディレクトリ
file_01.read # => current version file
file_01.read(revision: "version") # => old version file
directory_01.read # => ["file_xxx", "file_yyy", ...]
directory_01.read # => ["old_file_xxx", "old_file_yyy", ...]
```

### 8. エンコード

ファイルやメタデータ＋パーミッション情報をgzip圧縮、暗号化して保存しておく事ができる。  
デフォルトではエンコードしない設定になっているので、圧縮や暗号化をしたい場合には以下のように設定する。  
圧縮/暗号化は配列の順番通りに実行され、解凍/復号はその逆順に処理される。  
暗号化方式はOpenSSL AES-256-CBCで、パスワードには環境変数 STORE_AGENT_DATA_ENCODER_PASSWORD を使用する。  
STORE_AGENT_DATA_ENCODER_PASSWORD が設定されていない場合には空文字列がパスワードとして使用される。  

```ruby
# set config
StoreAgent.configure do |c|
  # ファイルを暗号化する
  c.storage_data_encoders = [StoreAgent::DataEncoder::OpensslAes256CbcEncoder.new]
  # メタデータやパーミッション情報をgzip圧縮した上で暗号化する
  c.attachment_data_encoders = [] <<
    StoreAgent::DataEncoder::GzipEncoder.new <<
    StoreAgent::DataEncoder::OpensslAes256CbcEncoder.new
  # 暗号化してからgzip圧縮する場合は以下の順に指定する
  # c.attachment_data_encoders = [] <<
  #   StoreAgent::DataEncoder::OpensslAes256CbcEncoder.new <<
  #   StoreAgent::DataEncoder::GzipEncoder.new
end
```

圧縮/暗号化されたファイルをシェル上から確認する場合は以下のようにする。  

```sh
### gzip圧縮のみ使用している場合
$ cat path/to/gzipped/file.txt
# 圧縮されたファイル
> ########

$ cat path/to/gzipped/file.txt | gunzip
# 元のファイル
> gunzipped file

### 暗号化のみ使用している場合
$ cat path/to/encrypted/file.txt
# 暗号化されたファイル
> Salted__########################

# パスワードは適宜変更する
$ openssl enc -d -aes-256-cbc -k "" -in path/to/encrypted/file.txt
# 元のファイル
> decoded file

### gzip圧縮した後に暗号化している場合
$ cat path/to/gzipped/and/encrypted/file.txt
# 圧縮＆暗号化されたファイル
> Salted__########################

$ openssl enc -d -aes-256-cbc -k "" -in path/to/gzipped/and/encrypted/file.txt | gunzip
# 元のファイル
> decoded and gunzipped file

### 暗号化した後にgzip圧縮している場合
$ cat path/to/encrypted/and/gzipped/file.txt
# 暗号化＆圧縮されたファイル
> ########

$ cat path/to/encrypted/and/gzipped/file.txt | gunzip | openssl enc -d -aes-256-cbc -k ""
# 元のファイル
> gunzipped and decoded file
```

### ディレクトリ構造

ストレージ領域のディレクトリ構造は以下のようになる。  
.git と .keep はバージョン管理を使用している場合にのみ作成される。  

```
storage_root/
  ├ ...
  └ workspace/
      ├ .git/
      ├ permission/
      |   ├ .perm
      |   ├ ...
      |   └ directory_x/
      |       ├ .perm
      |       ├ file_1.perm
      |       ├ ...
      |       └ file_n.perm
      ├ metadata/
      |   ├ .meta
      |   ├ .meta.lock
      |   ├ ...
      |   └ directory_x/
      |       ├ .meta
      |       ├ .meta.lock
      |       ├ file_1.meta
      |       ├ file_1.meta.lock
      |       ├ ...
      |       ├ file_n.meta
      |       └ file_n.meta.lock
      └ storage/
          ├ .keep
          ├ ...
          └ directory_x/
              ├ .keep
              ├ file_1
              ├ ...
              └ file_n
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/store_agent/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
