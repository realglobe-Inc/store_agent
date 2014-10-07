require "spec_helper"
require "store_agent/version_manager/git_shared_context"

RSpec.describe StoreAgent::VersionManager::RubyGit do
  before :all do
    require "git"
    StoreAgent.configure do |c|
      c.version_manager = StoreAgent::VersionManager::RubyGit
    end
  end
  let :workspace_name do
    "ruby_git_test"
  end

  include_context "git"
end
