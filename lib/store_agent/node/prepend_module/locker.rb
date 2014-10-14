module StoreAgent
  module Node
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
      def copy(dest_path = nil, *)
        super
      end

      # TODO
      def move(dest_path = nil, *)
        super
      end

      def get_metadata(*)
        lock!(lock_mode: File::LOCK_SH, recursive: true) do
          super
        end
      end

      def get_permissions(*)
        lock!(lock_mode: File::LOCK_SH, recursive: true) do
          super
        end
      end

      def chown(*)
        lock!(lock_mode: File::LOCK_EX, recursive: false) do
          super
        end
      end

      # TODO recursive_to_root, recursive_to_leaf
      # TODO lock_shared recursive_to_root
      def set_permission(*)
        lock!(lock_mode: File::LOCK_EX, recursive: false) do
          super
        end
      end

      # TODO
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
