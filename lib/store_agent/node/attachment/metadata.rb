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
  module Node
    # ファイルサイズ、作成者、更新日時などの情報
    class Metadata < Attachment
      def_delegators :data, *%w([] []=)

      def create
        super
        parent.update(disk_usage: disk_usage, directory_file_count: 1, tree_file_count: 1, recursive: true)
      end

      def update(disk_usage: 0, directory_file_count: 0, tree_file_count: 0, recursive: false)
        if directory?
          self["directory_file_count"] += directory_file_count
          self["tree_file_count"] += tree_file_count
        end
        self.disk_usage += disk_usage
        save
        if recursive
          parent.update(disk_usage: disk_usage, tree_file_count: tree_file_count, recursive: recursive)
        end
      end

      def delete
        parent.update(disk_usage: -disk_usage, directory_file_count: -1, tree_file_count: -1, recursive: true)
        super
      end

      def base_path # :nodoc:
        "#{@object.workspace.metadata_dirname}#{@object.path}"
      end

      # オブジェクトのメタデータを保存しているファイルの絶対パス
      def file_path
        "#{base_path}#{StoreAgent.config.metadata_extension}"
      end

      # ディスク使用量をバイトからキロバイトなどの単位に変換するメソッド
      def self.datasize_format(size)
        byte_names = %w(KB MB GB TB PB)
        byte_length = size.abs.to_s(2).length
        if byte_length <= 10
          "#{size} bytes"
        else
          exponent = [byte_names.length, (byte_length - 1) / 10].min
          sprintf("%0.2f%s", size.to_f / (2 ** (10 * exponent)), byte_names[exponent - 1])
        end
      end

      def disk_usage
        if directory?
          self["directory_bytes"]
        else
          self["bytes"]
        end
      end

      def disk_usage=(usage)
        usage_string = StoreAgent::Node::Metadata.datasize_format(usage)
        if directory?
          self["directory_size"] = usage_string
          self["directory_bytes"] = usage
        else
          self["size"] = usage_string
          self["bytes"] = usage
        end
      end

      def owner=(identifier)
        self["owner"] = identifier
      end

      def updated_at=(time)
        self["updated_at"] = time.to_s
        self["updated_at_unix_timestamp"] = time.to_i
      end

      private

      def parent
        if root?
          SuperRootMetadata.new
        else
          object.parent_directory.metadata
        end
      end

      def initial_data
        object.default_metadata
      end

      # 最上位階層の親ディレクトリのメタデータとして振る舞うダミーのクラス
      class SuperRootMetadata < Metadata # :nodoc:
        def initialize(*)
        end

        def update(*)
        end
      end
    end
  end
end
