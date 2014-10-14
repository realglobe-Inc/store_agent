module StoreAgent
  class VersionManager
    class RubyGit < VersionManager
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

      def remove(*paths)
        super do
          repository.remove(paths)
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
      end

      def read_file(path: ".", revision: "HEAD")
        repository.gblob("#{revision}:#{relative_path(path)}").contents
      end
    end
  end
end
