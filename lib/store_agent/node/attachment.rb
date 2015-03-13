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
    # メタデータや権限情報など、オブジェクトに付属する情報<br>
    # データはJSON形式のファイルで保存され、ハッシュ形式のデータとしてアクセスできる
    class Attachment
      extend Forwardable
      include StoreAgent::Validator

      attr_reader :object
      def_delegators :object, *%w(current_user root? directory?)

      def initialize(object: nil) # :nodoc:
        @object = object
        validates_to_be_not_nil_value!(:object)
      end

      # ハッシュ形式のデータにアクセスするためのメソッド
      def data
        @data ||= (load || initial_data)
      end

      # オブジェクトの作成時に一緒に作成される
      def create
        dirname = File.dirname(file_path)
        if !File.exists?(dirname)
          FileUtils.mkdir(dirname)
        end
        save
      end

      # オブジェクトの削除時に一緒に削除される
      def delete
        if object.directory?
          FileUtils.remove_dir(File.dirname(file_path))
        else
          FileUtils.rm(file_path)
        end
        object.workspace.version_manager.remove(file_path)
      end

      # データをファイルに保存するメソッド
      def save
        json_data = Oj.dump(data, mode: :compat, indent: StoreAgent.config.json_indent_level)
        encoded_data = StoreAgent.config.attachment_data_encoders.inject(json_data) do |data, encoder|
          encoder.encode(data)
        end
        open(file_path, File::WRONLY | File::CREAT) do |f|
          f.truncate(0)
          f.write encoded_data
        end
        object.workspace.version_manager.add(file_path)
        reload
      end

      # データをファイルから読み込むメソッド
      def load
        if File.exists?(file_path)
          encoded_data = open(file_path, "rb").read
          json_data = StoreAgent.config.attachment_data_encoders.reverse.inject(encoded_data) do |data, encoder|
            encoder.decode(data)
          end
          Oj.load(json_data)
        end
      end

      # 保存されていない変更を破棄する
      def reload
        @data = nil
        self
      end

      def inspect # :nodoc:
        Oj.dump(data, mode: :compat, indent: 2)
      end
    end
  end
end
