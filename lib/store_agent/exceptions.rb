# Copyright 2015 realglobe, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module StoreAgent
  # 引数として渡されたパスが不正な場合に発生する例外クラス
  #   workspace.directory("invalid/directory/path").create
  #   # => 既にディレクトリがある場合、例外が発生する
  #   workspace.file("invalid/file/path").delete
  #   # => 指定したパスにファイルが存在しない場合、例外が発生する
  class InvalidPathError < StandardError
  end

  # ファイルのコピー/移動時に、コピー元とコピー先の種類が違う場合に発生する例外クラス
  #   workspace.directory("path/to/directory").copy("path/to/file")
  #   # => ディレクトリのコピー先にファイルが存在する場合、例外が発生する
  class InvalidNodeTypeError < StandardError
    attr_reader :src_object, :dest_object # :nodoc:

    def initialize(src_object: nil, dest_object: nil)
      @src_object = src_object
      @dest_object = dest_object
    end

    def to_s # :nodoc:
      if @src_object && @dest_object
        "invalid node type: '#{@src_object.path}' is #{@src_object.filetype}, '#{@dest_object.path}' is #{@dest_object.filetype}"
      else
        "invalid node type"
      end
    end
  end

  # 権限が無いユーザーでファイルの読み書きなどを行った場合に発生する例外クラス
  #   guest_user.workspace("wc").file("file").create("file body")
  #   # => ファイルの書き込み権限が無い場合、例外が発生する
  class PermissionDeniedError < StandardError
    attr_reader :errors, :object, :permission # :nodoc:

    # 操作対象が1つの場合には object と permission を渡す。<br>
    # ディレクトリの削除時など、操作対象が複数ある場合には errors に例外の配列を渡す。
    def initialize(errors: nil, object: nil, permission: "")
      @errors = errors
      @object = object
      @permission = permission
    end

    def to_s # :nodoc:
      if @errors
        "permission denied: user=#{@errors.first.object.current_user.identifiers} " +
        @errors.map do |e|
          "workspace=#{e.object.workspace.namespace} permission=#{e.permission} object=#{e.object.path}"
        end.join(", ")
      else
        "permission denied: user=#{object.current_user.identifiers} workspace=#{object.workspace.namespace} permission=#{permission} object=#{object.path}"
      end
    end
  end

  # バージョン管理時に、不正なリビジョンが指定された場合に発生する例外クラス
  #   workspace.file("path/to/file").read(revision: "invalid revision")
  #   # => 存在しないリビジョンを指定した場合、例外が発生する
  class InvalidRevisionError < StandardError
    attr_reader :path, :revision # :nodoc:

    def initialize(path: "", revision: "")
      @path = path
      @revision = revision
    end

    def to_s # :nodoc:
      "invalid revision: path=#{path} revision=#{revision}"
    end
  end
end
