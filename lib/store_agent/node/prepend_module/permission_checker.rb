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
    # オブジェクトの操作時に権限があるかどうかをチェックするモジュール
    module PermissionChecker
      def create(*)
        if !root?
          parent_directory.authorize!("write")
        end
        super
      end

      def read(*)
        authorize!("read")
        super
      end

      def update(*)
        authorize!("write")
        super
      end

      def delete(*)
        authorize!("write")
        super
      end

      def touch(*)
        authorize!("read")
        super
      end

      # TODO
      # コピー先のwrite権限をチェックする
      def copy(dest_path = nil, *)
        authorize!("read")
        super
      end

      # TODO
      # コピー先のwrite権限をチェックする
      def move(dest_path = nil, *)
        authorize!("write")
        super
      end

      def get_metadata(*) # :nodoc:
        authorize!("read")
        super
      end

      def get_permissions(*) # :nodoc:
        authorize!("read")
        super
      end

      def chown(*)
        authorize!("chown")
        super
      end

      def set_permission(*)
        authorize!("chmod")
        super
      end

      def unset_permission(*)
        authorize!("chmod")
        super
      end

      protected

      def authorize!(permission_name)
        if !permission.allow?(permission_name)
          raise StoreAgent::PermissionDeniedError.new(object: self, permission: permission_name)
        end
      end
    end
  end
end
