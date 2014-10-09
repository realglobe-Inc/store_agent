require "spec_helper"

RSpec.describe StoreAgent::Workspace do
  let :user do
    StoreAgent::User.new("foo", "bar")
  end

  context "初期化のテスト" do
    it "パラメータが無い Workspace は作成できない" do
      expect do
        StoreAgent::Workspace.new
      end.to raise_error
    end
    it "パラメータに namespace が無い Workspace は作成できない" do
      expect do
        StoreAgent::Workspace.new(current_user: user, foo: :bar)
      end.to raise_error
    end
    it "namespace パラメータに / が入っている Workspace は作成できない" do
      expect do
        StoreAgent::Workspace.new(current_user: user, namespace: "foo/bar")
      end.to raise_error
    end
    it "User を紐づけないと Workspace を作成できない" do
      expect do
        StoreAgent::Workspace.new(namespace: "bar")
      end.to raise_error
    end
    it "namespace が正しく、User が紐づいていれば Workspace を作成できる" do
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
end
