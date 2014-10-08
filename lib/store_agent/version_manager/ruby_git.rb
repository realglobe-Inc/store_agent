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
        super do
          yield
        end
        repository.commit(message)
      rescue => e
        repository.reset_hard
        raise e
      end

      def last_commit_id
        logs(".").first.objectish
      end

      def revisions(path)
        logs(path).map(&:objectish)
      end

      def logs(path)
        repository.log.path(path)
      end

      private

      def repository
        @repository ||= Git.open(workspace.namespace_dirname)
      end
    end
  end
end
