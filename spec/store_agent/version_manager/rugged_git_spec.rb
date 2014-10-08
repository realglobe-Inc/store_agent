require "spec_helper"
require "store_agent/version_manager/git_shared_context"

RSpec.describe StoreAgent::VersionManager::RuggedGit do
  before :all do
    require "rugged"
    StoreAgent.configure do |c|
      c.version_manager = StoreAgent::VersionManager::RuggedGit
    end
  end
  let :workspace_name do
    "rugged_git_test"
  end

  include_context "git"
end
