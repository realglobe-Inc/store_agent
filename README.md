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

TODO: Write usage instructions here

```ruby
# ユーザー
user = StoreAgent::User.new("user_xxx")
# ルートユーザー
root_user = StoreAgent::Superuser.new
# ゲストユーザー
guest_user = StoreAgent::Guest.new

# ワークスペース
workspace = user.workspace("workspace_01")
workspace.exists? # => false
workspace.create
workspace.exists? # => true

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

# メタデータ
p directory_01.metadata # => {...}
p file_01.metadata # => {...}

# パーミッション変更
file_01.set_permission(identifier: "user_yyy", permission_values: {"read" => true, "write" => false})
directory_01.set_permission(identifier: "user_yyy", permission_values: {"read" => true})
directory_02.set_permission(identifier: "user_yyy", permission_values: {"read" => true, "write" => true}, recursive: true)

# パーミッション解除
file_01.unset_permission(identifier: "user_yyy", permission_names: "read")
directory_01.unset_permission(identifier: "user_yyy", permission_names: ["read"])
directory_02.unset_permission(identifier: "user_yyy", permission_names: ["read", "write"], recursive: true)
```

## VersionManager

デフォルトではバージョン管理をしない設定になっている。  
gitでバージョン管理する場合、以下のように設定する。  

1. [rugged](https://github.com/libgit2/rugged)を使用する場合  

```ruby
# Gemfile
gem "rugged"

# initialize
StoreAgent.configure do |c|
  c.version_manager = StoreAgent::VersionManager::RuggedGit
end
```

2. [ruby-git](https://github.com/schacon/ruby-git)を使用する場合  

```ruby
# Gemfile
gem "git"

# initialize
StoreAgent.configure do |c|
  c.version_manager = StoreAgent::VersionManager::RubyGit
end
```

過去のバージョンのファイルやディレクトリを読み込む場合は以下のように実行する。  

```ruby
file_or_directory.read(revision: "version")
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/store_agent/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
