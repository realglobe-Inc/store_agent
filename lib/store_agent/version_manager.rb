require "store_agent/version_manager/rugged_git"
require "store_agent/version_manager/ruby_git"

module StoreAgent
  class VersionManager
    attr_reader :workspace

    def self.reserved_filenames
      []
    end

    def initialize(workspace: nil)
      @workspace = workspace
    end

    %w(init add remove transaction).each do |method_name|
      define_method method_name do |*, &block|
        FileUtils.cd(workspace.namespace_dirname) do
          if block
            block.call
          end
        end
      end
    end

    private

    def relative_path(path)
      path[(workspace.namespace_dirname.length + 1)..-1]
    end
  end
end
