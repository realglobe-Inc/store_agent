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
    # ディレクトリ
    class DirectoryObject < Object
      def initialize(params) # :nodoc:
        super
        if !@path.end_with?("/")
          @path = "#{@path}/"
        end
      end

      def create
        super do
          if block_given?
            yield self
          end
          FileUtils.mkdir(storage_object_path)
          workspace.version_manager.add("#{storage_object_path}.keep")
        end
      end

      def read(revision: nil)
        super do
          filenames =
            if revision.nil?
              current_children_filenames
            else
              workspace.version_manager.read(path: storage_object_path, revision: revision)
            end
          filenames - StoreAgent.reserved_filenames
        end
      end

      def update
        raise "cannot update directory"
      end

      def delete(*)
        super do
          success, errors = call_for_children do |child|
            child.delete(recursive: false)
          end
          if success
            FileUtils.remove_dir(storage_object_path)
          else
            raise StoreAgent::PermissionDeniedError.new(errors: errors)
          end
          workspace.version_manager.remove(storage_object_path, directory: true)
        end
      end

      def touch(*, recursive: false)
        super do
          FileUtils.touch("#{storage_object_path}.keep")
          workspace.version_manager.add("#{storage_object_path}.keep")
          if recursive
            success, errors = call_for_children do |child|
              child.touch(recursive: true)
            end
          end
        end
      end

      def copy(dest_path = nil, *)
        super do
          dest_directory = build_dest_directory(dest_path).create
          success, errors = call_for_children do |child|
            child.copy("#{dest_directory.path}#{File.basename(child.path)}")
          end
        end
      end

      def move(dest_path = nil, *)
        super do
          dest_directory = build_dest_directory(dest_path)
          disk_usage = metadata.disk_usage
          file_count = directory_file_count
          FileUtils.mv(storage_object_path, dest_directory.storage_object_path)
          FileUtils.mv(metadata.base_path, dest_directory.metadata.base_path)
          FileUtils.mv(permission.base_path, dest_directory.permission.base_path)
          dest_directory.touch(recursive: true)
          dest_directory.parent_directory.metadata.update(disk_usage: disk_usage, directory_file_count: 1, tree_file_count: file_count + 1, recursive: true)
          parent_directory.metadata.update(disk_usage: -disk_usage, directory_file_count: -1, tree_file_count: -(file_count + 1), recursive: true)

          [storage_object_path, metadata.base_path, permission.base_path].each do |dir_path|
            workspace.version_manager.remove(dir_path, directory: true)
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

      def chown(*, identifier: nil, recursive: false)
        super do
          if recursive
            success, errors = call_for_children do |child|
              child.chown(identifier: identifier, recursive: recursive)
            end
          end
        end
      end

      def set_permission(identifier: nil, permission_values: {}, recursive: false)
        super do
          if recursive
            success, errors = call_for_children do |child|
              child.set_permission(identifier: identifier, permission_values: permission_values)
            end
          end
        end
      end

      def unset_permission(identifier: nil, permission_names: [], recursive: false)
        super do
          if recursive
            success, errors = call_for_children do |child|
              child.unset_permission(identifier: identifier, permission_names: permission_names)
            end
          end
        end
      end

      # 引数を現在のパスからの相対パスとして解釈し、オブジェクトのインスタンスを返す
      def find_object(path)
        object = StoreAgent::Node::Object.new(workspace: workspace, path: namespaced_absolute_path(path))
        case object.exists? && object.filetype
        when false
          virtual(path)
        when "directory"
          directory(path)
        when "file"
          file(path)
        else
          raise "unknown filetype"
        end
      end

      def virtual(path) # :nodoc:
        StoreAgent::Node::VirtualObject.new(workspace: workspace, path: namespaced_absolute_path(path))
      end

      # 現在のパスからの相対パスで、ディレクトリオブジェクトのインスタンスを返す
      def directory(path)
        StoreAgent::Node::DirectoryObject.new(workspace: workspace, path: namespaced_absolute_path(path))
      end

      # 現在のパスからの相対パスで、ファイルオブジェクトのインスタンスを返す
      def file(path)
        StoreAgent::Node::FileObject.new(workspace: workspace, path: namespaced_absolute_path(path))
      end

      # 現在のディレクトリの直下にあるオブジェクトの一覧を返す
      def children
        (current_children_filenames - StoreAgent.reserved_filenames).map{|filename|
          find_object(filename)
        }
      end

      def default_metadata # :nodoc:
        super.merge(directory_metadata)
      end

      def directory_metadata # :nodoc:
        {
          "is_dir" => true,
          "directory_size" => StoreAgent::Node::Metadata.datasize_format(initial_bytesize),
          "directory_bytes" => initial_bytesize,
          "directory_size_limit" => StoreAgent::Node::Metadata.datasize_format(StoreAgent.config.default_directory_bytesize_limit),
          "directory_bytes_limit" => StoreAgent.config.default_directory_bytesize_limit,
          "directory_file_count" => 0,
          "tree_file_count" => 0
        }
      end

      # ディレクトリ直下にあるファイル数
      def directory_file_count
        metadata["directory_file_count"]
      end

      # ディレクトリ以下のツリー全体でのファイル数
      def tree_file_count
        metadata["tree_file_count"]
      end

      def directory? # :nodoc:
        true
      end

      private

      def namespaced_absolute_path(path)
        "#{@path}#{sanitize_path(path)}"
      end

      def initial_bytesize
        File.size(storage_object_path)
      end

      def build_dest_directory(dest_path)
        dest_object = workspace.find_object(dest_path)
        case
        when dest_object.file?
          raise InvalidNodeTypeError.new(src_object: self, dest_object: dest_object)
        when dest_object.directory?
          sub_directory_object = dest_object.find_object(File.basename(path))
          if sub_directory_object.exists?
            raise InvalidPathError, "object already exists: #{sub_directory_object.path}"
          end
          dest_object.directory(File.basename(path))
        else
          workspace.directory(dest_path)
        end
      end

      def current_children_filenames
        FileUtils.cd(storage_object_path) do
          return Dir.glob("*", File::FNM_DOTMATCH)
        end
      end

      def call_for_children
        errors = []
        children.each do |child|
          begin
            yield child
          rescue StoreAgent::PermissionDeniedError => e
            errors << e
          end
        end
        return errors.empty?, errors
      end
    end
  end
end
