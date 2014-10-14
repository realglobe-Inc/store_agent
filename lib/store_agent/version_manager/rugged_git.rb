module StoreAgent
  class VersionManager
    class RuggedGit < VersionManager
      def self.reserved_filenames
        %w(.git .keep)
      end

      def init
        super do
          Rugged::Repository.init_at(".")
        end
      end

      def add(*paths)
        super do
          FileUtils.touch(paths)
          paths.flatten.each do |path|
            oid = Rugged::Blob.from_workdir(repository, relative_path(path))
            repository.index.add(relative_path(path))
          end
        end
      end

      def remove(*paths)
        super do
          paths.flatten.each do |path|
            repository.index.remove(relative_path(path))
          end
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
            commit(message)
          rescue => e
            repository.reset("HEAD", :hard)
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

      def revisions(path = "*")
        logs(path).map(&:oid)
      end

      private

      def repository
        @repository ||= Rugged::Repository.new(workspace.namespace_dirname)
      end

      def walker
        @walker ||= Rugged::Walker.new(repository)
      end

      def logs(path)
        walker.sorting(Rugged::SORT_DATE)
        walker.push(repository.head.target)
        walker.select do |commit|
          commit.parents.size == 1 && commit.diff(paths: [path]).size > 0
        end
      end

      def lookup_path(path: "", revision: nil)
        paths = relative_path(path).split("/")
        paths.inject(repository.lookup(revision).tree) do |tree, path|
          repository.lookup(tree.find{|t| t[:name] == path}[:oid])
        end
      end

      def read_directory(path: "", revision: nil)
        lookup_path(path: path, revision: revision).map{|t| t[:name]}
      end

      def read_file(path: "", revision: nil)
        lookup_path(path: path, revision: revision).content
      end

      def commit(message)
        options = {
          tree: repository.index.write_tree(repository),
          message: message,
          parents: repository.empty? ? [] : [ repository.head.target ].compact,
          update_ref: "HEAD"
        }
        Rugged::Commit.create(repository, options)
        repository.index.write
      end
    end
  end
end
