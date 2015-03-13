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
