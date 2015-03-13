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

require "store_agent/version_manager/rugged_git"
require "store_agent/version_manager/ruby_git"

module StoreAgent
  # バージョン管理に使用するクラスの雛形。<br>
  # デフォルトではこのクラスが使用されるが、その場合はバージョン管理を行わない。
  class VersionManager
    attr_reader :workspace

    # バージョン管理システムが使用するため予約されているファイル名<br>
    # 例えば git の場合は、.git .keep など
    def self.reserved_filenames
      []
    end

    def initialize(workspace: nil) # :nodoc:
      @workspace = workspace
    end

    # :call-seq:
    #   init
    #
    # バージョン管理対象のリポジトリを初期化する
    def init(*params, &block)
      call_block(params, &block)
    end

    # :call-seq:
    #   add(*paths)
    #
    # 引数で渡されたパスをバージョン管理対象に追加する
    def add(*params, &block)
      call_block(params, &block)
    end

    # :call-seq:
    #   remove(*paths, directory: false)
    #
    # 引数で渡されたパスをバージョン管理対象から除外する<br>
    # パスがディレクトリの場合には、directory に true が渡される
    def remove(*params, &block)
      call_block(params, &block)
    end

    # :call-seq:
    #   transaction(messsage, &block)
    #
    # 引数でコミットメッセージとブロックを受け取り、トランザクション処理で実行する<br>
    # ブロックの実行に成功した場合には受け取ったメッセージで変更をコミットする。<br>
    # 処理に失敗した場合は、ブロックの実行前の状態に戻す。
    def transaction(*params, &block)
      call_block(params, &block)
    end

    # :call-seq:
    #   read(path: "", revision: nil)
    #
    # 指定されたパスの指定リビジョン時の中身を返す
    def read(*params, &block)
      call_block(params, &block)
    end

    # :call-seq:
    #   revisions(path)
    #
    # 引数で渡されたパスのリビジョン一覧を返す
    def revisions(*params, &block)
      call_block(params, &block)
    end

    private

    def relative_path(path)
      path[(workspace.namespace_dirname.length + 1)..-1]
    end

    def call_block(*, &block)
      FileUtils.cd(workspace.namespace_dirname) do
        if block
          yield
        end
      end
    end
  end
end
