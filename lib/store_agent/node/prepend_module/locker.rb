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
  module Node
    # オブジェクトの読み書き時にファイルをロックするモジュール
    module Locker
      def create(*)
        lock!(lock_mode: File::LOCK_EX, recursive: true) do
          super
        end
      end

      def read(*)
        lock!(lock_mode: File::LOCK_SH, recursive: true) do
          super
        end
      end

      def update(*)
        lock!(lock_mode: File::LOCK_EX, recursive: true) do
          super
        end
      end

      def delete(*, recursive: true)
        lock!(lock_mode: File::LOCK_EX, recursive: recursive) do
          super
        end
      end

      def touch(*)
        lock!(lock_mode: File::LOCK_SH, recursive: true) do
          super
        end
      end

      # TODO
      # コピー元を共有ロック、コピー先を排他ロックする
      def copy(dest_path = nil, *)
        super
      end

      # TODO
      # 移動元と移動先を排他ロックする
      def move(dest_path = nil, *)
        super
      end

      def get_metadata(*) # :nodoc:
        lock!(lock_mode: File::LOCK_SH, recursive: true) do
          super
        end
      end

      def get_permissions(*) # :nodoc:
        lock!(lock_mode: File::LOCK_SH, recursive: true) do
          super
        end
      end

      def chown(*)
        lock!(lock_mode: File::LOCK_EX, recursive: false) do
          super
        end
      end

      # TODO
      # 親階層のファイルをロックする
      def set_permission(*)
        lock!(lock_mode: File::LOCK_EX, recursive: false) do
          super
        end
      end

      # TODO
      # 親階層のファイルをロックする
      def unset_permission(*)
        lock!(lock_mode: File::LOCK_EX, recursive: false) do
          super
        end
      end

      protected

      # TODO
      def lock_file_path
        "#{metadata.file_path}.lock"
      end

      def lock!(lock_mode: File::LOCK_SH, recursive: false, &block)
        proc = Proc.new do
          if !File.exists?(dirname = File.dirname(lock_file_path))
            FileUtils.mkdir(dirname)
          end
          open(lock_file_path, File::RDWR | File::CREAT) do |f|
            timeout(StoreAgent.config.lock_timeout) do
              f.flock(lock_mode)
            end
            f.truncate(0)
            yield
          end
        end
        if recursive && !root?
          parent_directory.lock!(lock_mode: lock_mode, recursive: recursive, &proc)
        else
          proc.call
        end
      end
    end
  end
end
