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
  class VersionManager
    # ruby-git(https://github.com/schacon/ruby-git) を使用してバージョン管理を行うクラス<br>
    # StoreAgent::VersionManager を継承しているので、詳細はそちらを参照
    class RubyGit < VersionManager
      # :enddoc:
      def self.reserved_filenames
        %w(.git .keep)
      end

      def init
        super do
          Git.init
        end
      end

      def add(*paths)
        super do
          FileUtils.touch(paths)
          repository.add(paths, force: true)
        end
      end

      def remove(*paths, **_)
        super do
          repository.remove(paths, recursive: true)
        end
      end

      def transaction(message)
        if @transaction
          yield
        else
          begin
            @transaction = true
            super do
              yield
            end
            repository.commit(message)
          rescue => e
            repository.reset_hard
            raise e
          ensure
            @transaction = false
          end
        end
      end

      def read(path: "", revision: nil)
        if path.end_with?("/")
          read_directory(path: path, revision: revision)
        else
          read_file(path: path, revision: revision)
        end
      end

      def revisions(path = ".")
        logs(path).map(&:objectish)
      end

      private

      def repository
        @repository ||= Git.open(workspace.namespace_dirname)
      end

      def logs(path)
        repository.log.path(path)
      end

      def read_directory(path: ".", revision: "HEAD")
        repository.gtree("#{revision}:#{relative_path(path)}").children.keys
      rescue Git::GitExecuteError
        raise StoreAgent::InvalidRevisionError.new(path: path, revision: revision)
      end

      def read_file(path: ".", revision: "HEAD")
        repository.gblob("#{revision}:#{relative_path(path)}").contents
      rescue Git::GitExecuteError
        raise StoreAgent::InvalidRevisionError.new(path: path, revision: revision)
      end
    end
  end
end
