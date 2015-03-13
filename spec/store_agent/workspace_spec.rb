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

RSpec.describe StoreAgent::Workspace do
  let :user do
    StoreAgent::User.new("foo", "bar")
  end

  context "初期化のテスト" do
    it "パラメータが無い Workspace は初期化できない" do
      expect do
        StoreAgent::Workspace.new
      end.to raise_error
    end
    it "パラメータに namespace が無い Workspace は初期化できない" do
      expect do
        StoreAgent::Workspace.new(current_user: user, foo: :bar)
      end.to raise_error
    end
    it "namespace パラメータに / が入っている Workspace は初期化できない" do
      expect do
        StoreAgent::Workspace.new(current_user: user, namespace: "foo/bar")
      end.to raise_error
    end
    it "User を紐づけないと Workspace を初期化できない" do
      expect do
        StoreAgent::Workspace.new(namespace: "bar")
      end.to raise_error
    end
    it "namespace が正しく、User が紐づいていれば Workspace を初期化できる" do
      expect(StoreAgent::Workspace.new(current_user: user, namespace: "bar").namespace).to eq "bar"
    end
  end

  context "各種ディレクトリのパスに対するテスト" do
    let :workspace do
      user.workspace("bar")
    end

    it "namespace のルート" do
      expect(workspace.namespace_dirname).to eq "/tmp/store_agent/bar"
    end
    it "オブジェクトを格納する領域" do
      expect(workspace.storage_dirname).to eq "/tmp/store_agent/bar/storage"
    end
    it "メタデータを格納する領域" do
      expect(workspace.metadata_dirname).to eq "/tmp/store_agent/bar/metadata"
    end
  end

  context "Workspace の作成" do
    it "名前が重複する Workspace は作成できない" do
      user.workspace("ws_create").create
      expect do
        user.workspace("ws_create").create
      end.to raise_error StoreAgent::InvalidPathError
    end
  end
  context "Workspace の削除" do
    it "存在しない Workspace を削除しようとすると例外が発生する" do
      user.workspace("ws_delete").create
      expect(user.workspace("ws_delete").exists?).to eq true
      user.workspace("ws_delete").delete
      expect(user.workspace("ws_delete").exists?).to eq false
      expect do
        user.workspace("ws_delete").delete
      end.to raise_error StoreAgent::InvalidPathError
    end
  end
  context "Workspace.name_list で Workspace名の一覧が取得できる" do
    before do
      StoreAgent.configure do |c|
        c.storage_root = "/tmp/store_agent_ws_name_list"
      end
      if File.exists?(StoreAgent.config.storage_root)
        FileUtils.remove_dir(StoreAgent.config.storage_root)
      end
    end
    after do
      StoreAgent.configure do |c|
        c.storage_root = "/tmp/store_agent"
      end
    end

    it "" do
      expect(StoreAgent::Workspace.name_list).to eq []
      user.workspace("foo").create
      user.workspace("bar").create
      expect(StoreAgent::Workspace.name_list.sort).to eq ["bar", "foo"]
    end
  end
end
