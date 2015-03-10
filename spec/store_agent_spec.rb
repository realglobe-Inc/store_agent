require "spec_helper"

RSpec.describe StoreAgent do
  context "initialize" do
    it do
      user = StoreAgent::User.new("current_user_id")
      new_workspace = user.workspace("new_namespace")
      expect(new_workspace.exists?).to be false
      new_workspace.create
      expect(new_workspace.exists?).to be true
      root_dir = new_workspace.directory("/")
      expect(root_dir.exists?).to be true
#      expect(root_dir.metadata.data).to eq({})
      expect(root_dir.permission.allow?("read")).to be true
      expect(root_dir.permission.allow?("write")).to be true
#      root_dir.metadata = {foo: :bar}
#      expect(root_dir.metadata.data).to eq({foo: :bar})
#      root_dir.metadata["hoge"] = "fuga"
#      expect(root_dir.metadata[:foo]).to eq :bar
#      expect(root_dir.metadata.data).to eq({foo: :bar, "hoge" => "fuga"})
      root_dir.metadata.save
      root_dir.metadata.reload
#      expect(root_dir.metadata.data).to eq({"foo" => "bar", "hoge" => "fuga"})
#      expect(new_workspace.directory("/").metadata["foo"]).to eq "bar"
      new_dir = new_workspace.directory("/foo")
      expect(new_dir.exists?).to be false
      new_dir.create
      expect(new_dir.exists?).to be true
      new_file = new_workspace.file("/foo/bar.txt")
      expect(new_file.exists?).to be false
      expect do
        new_file.read
      end.to raise_error
      new_file.create
      new_file.body = "save body"
      new_file.save
      expect(new_file.read).to eq "save body"
      new_file.update("body string")
      expect(new_file.read).to eq "body string"

      user_2 = StoreAgent::User.new("another_user_id")
      file = user_2.workspace("new_namespace").file("/foo/bar.txt")
      expect(file.exists?).to be true
      expect(file.permission.allow?("read")).to be false
      expect(file.permission.allow?("write")).to be false
      expect do
        file.read
      end.to raise_error

#      raise new_dir.children.inspect
    end
  end
end
