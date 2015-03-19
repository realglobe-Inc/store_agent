#--
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
#++

module StoreAgent
  # ワークスペース
  class Workspace
    extend Forwardable
    include StoreAgent::Validator

    attr_reader :current_user, :namespace, :version_manager
    def_delegators :root, *%w(find_object directory file exists?)

    def initialize(current_user: nil, namespace: nil) # :nodoc:
      @current_user = current_user
      @namespace = namespace
      validates_to_be_not_nil_value!(:current_user)
      validates_to_be_string_or_symbol!(@namespace)
      validates_to_be_excluded_slash!(@namespace)
      @version_manager = StoreAgent.config.version_manager.new(workspace: self)
    end

    # ワークスペースを新規作成する
    def create
      if exists?
        raise InvalidPathError, "workspace #{@namespace} is already exists"
      end
      FileUtils.mkdir_p(namespace_dirname)
      @version_manager.init
      root.create
    end

    # ワークスペースを削除する
    def delete
      if !exists?
        raise InvalidPathError, "workspace #{@namespace} not found"
      end
      FileUtils.remove_dir(namespace_dirname)
    end

    # ワークスペースのファイルツリーの最上位ノード
    def root
      @root ||= StoreAgent::Node::DirectoryObject.new(workspace: self, path: "/")
    end

    # ワークスペースの絶対パス
    def namespace_dirname
      File.absolute_path("#{StoreAgent.config.storage_root}/#{@namespace}")
    end

    # ストレージとして使用する領域の絶対パス
    def storage_dirname
      File.absolute_path("#{namespace_dirname}/#{StoreAgent.config.storage_dirname}")
    end

    # メタデータの保存に使用する領域の絶対パス
    def metadata_dirname
      File.absolute_path("#{namespace_dirname}/#{StoreAgent.config.metadata_dirname}")
    end

    # 権限情報の保存に使用する領域の絶対パス
    def permission_dirname
      File.absolute_path("#{namespace_dirname}/#{StoreAgent.config.permission_dirname}")
    end

    # 全ワークスペース名の一覧を配列で返す
    def self.name_list
      if !File.exists?(StoreAgent.config.storage_root)
        FileUtils.mkdir_p(StoreAgent.config.storage_root)
      end
      FileUtils.cd(StoreAgent.config.storage_root) do
        return Dir.glob("*", File::FNM_DOTMATCH) - StoreAgent.reserved_filenames
      end
    end
  end
end
