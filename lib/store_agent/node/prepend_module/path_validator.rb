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
    # オブジェクトの操作時に、パスが不正でないかをチェックするモジュール
    module PathValidator
      def create(*)
        if !root?
          parent_directory.be_present!
        end
        be_absent!
        be_not_reserved!
        super
      end

      def read(*, revision: nil)
        if revision.nil?
          be_present!
        end
        be_not_reserved!
        super
      end

      def update(*)
        be_present!
        be_not_reserved!
        super
      end

      def delete(*)
        be_present!
        be_not_root!
        be_not_reserved!
        super
      end

      def touch(*)
        be_present!
        be_not_reserved!
        super
      end

      # TODO
      def copy(dest_path = nil, *)
        be_present!
        be_not_reserved!
        super
      end

      # TODO
      def move(dest_path = nil, *)
        be_present!
        be_not_root!
        be_not_reserved!
        super
      end

      def get_metadata(*) # :nodoc:
        be_present!
        be_not_reserved!
        super
      end

      def get_permissions(*) # :nodoc:
        be_present!
        be_not_reserved!
        super
      end

      def chown(*)
        be_present!
        be_not_reserved!
        super
      end

      def set_permission(*)
        be_present!
        be_not_reserved!
        super
      end

      def unset_permission(*)
        be_present!
        be_not_reserved!
        super
      end

      protected

      def be_present!
        if !exists?
          raise StoreAgent::InvalidPathError, "object not found: #{path}"
        end
      end

      def be_absent!
        if exists?
          raise StoreAgent::InvalidPathError, "object already exists: #{path}"
        end
      end

      def be_not_root!
        if root?
          raise StoreAgent::InvalidPathError, "can't delete root node"
        end
      end

      def be_not_reserved!
        basename = File.basename(path)
        reserved_extensions = [] <<
          StoreAgent.config.metadata_extension <<
          StoreAgent.config.permission_extension
        reserved_extensions.each do |extension|
          if basename.end_with?(extension)
            raise StoreAgent::InvalidPathError, "extension '#{extension}' is reserved"
          end
        end
        if StoreAgent.reserved_filenames.include?(basename)
          raise StoreAgent::InvalidPathError, "filename '#{basename}' is reserved"
        end
      end
    end
  end
end
