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
    # ファイル
    class FileObject < Object
      attr_writer :body

      def create(*params, &block)
        super do
          set_body(*params, &block)
          save
          workspace.version_manager.add(storage_object_path)
        end
      end

      def read(revision: nil)
        super do
          if revision.nil?
            encoded_data = open(storage_object_path) do |f|
              f.read
            end
          else
            encoded_data = workspace.version_manager.read(path: storage_object_path, revision: revision)
          end
          StoreAgent.config.attachment_data_encoders.reverse.inject(encoded_data) do |data, encoder|
            encoder.decode(data)
          end
        end
      end

      def update(*params, &block)
        super do
          set_body(*params, &block)
          if @body.nil?
            raise "file body required"
          end
          save
          disk_usage_diff = @body.length - metadata.disk_usage
          metadata.update(disk_usage: disk_usage_diff, recursive: true)
          workspace.version_manager.add(storage_object_path)
        end
      end

      def delete(*)
        super do
          FileUtils.rm(storage_object_path)
          workspace.version_manager.remove(storage_object_path)
        end
      end

      def touch(*)
        super do
          FileUtils.touch(storage_object_path)
          workspace.version_manager.add(storage_object_path)
        end
      end

      def copy(dest_path = nil, *)
        super do
          file_body = read
          dest_file = build_dest_file(dest_path)
          if dest_file.exists?
            dest_file.update(file_body)
          else
            dest_file.create(read)
          end
        end
      end

      def move(dest_path = nil, *)
        super do
          dest_file = build_dest_file(dest_path)
          if dest_file.exists?
            disk_usage_diff = metadata.disk_usage - dest_file.metadata.disk_usage
            file_count = 0
          else
            disk_usage_diff = metadata.disk_usage
            file_count = 1
          end
          FileUtils.mv(storage_object_path, dest_file.storage_object_path)
          FileUtils.mv(metadata.file_path, dest_file.metadata.file_path)
          FileUtils.mv(permission.file_path, dest_file.permission.file_path)
          dest_file.touch
          dest_file.parent_directory.metadata.update(disk_usage: disk_usage_diff, directory_file_count: file_count, tree_file_count: file_count, recursive: true)
          parent_directory.metadata.update(disk_usage: -dest_file.metadata.disk_usage, directory_file_count: -1, tree_file_count: -1, recursive: true)

          [storage_object_path, metadata.file_path, permission.file_path].each do |file_path|
            workspace.version_manager.remove(file_path)
          end
        end
      end

      def get_metadata(*) # :nodoc:
        super do
        end
      end

      def get_permissions(*) # :nodoc:
        super do
        end
      end

      def chown(*)
        super do
        end
      end

      def set_permission(*)
        super do
        end
      end

      def unset_permission(*)
        super do
        end
      end

      def find_object(_) # :nodoc:
        raise "#{@path} is not directory"
      end

      def directory(_) # :nodoc:
        raise "#{@path} is not directory"
      end

      def file(_) # :nodoc:
        raise "#{@path} is not directory"
      end

      def save
        encoded_data = StoreAgent.config.storage_data_encoders.inject(@body) do |data, encoder|
          encoder.encode(data)
        end
        open(storage_object_path, "w") do |f|
          f.write encoded_data
        end
      end

      def children # :nodoc:
        []
      end

      def file? # :nodoc:
        true
      end

      private

      def initial_bytesize
        (@body || "").size
      end

      def set_body(*params)
        case
        when block_given?
          yield self
        when (options = params.first).is_a?(String)
          @body = options
        when options.is_a?(Symbol)
          @body = options.to_s
        when options.is_a?(Hash)
          @body = options["body"] || options[:body]
        else
          @body = nil
        end
      end

      def build_dest_file(dest_path)
        dest_object = workspace.find_object(dest_path)
        if dest_object.directory?
          sub_directory_object = dest_object.find_object(File.basename(path))
          if sub_directory_object.directory?
            raise InvalidNodeTypeError.new(src_object: self, dest_object: sub_directory_object)
          end
          dest_object.file(File.basename(path))
        else
          workspace.file(dest_path)
        end
      end
    end
  end
end
