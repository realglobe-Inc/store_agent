RSpec.shared_context "git" do
  after :all do
    StoreAgent.configure do |c|
      c.version_manager = StoreAgent::VersionManager
    end
  end
  let :user do
    StoreAgent::User.new("foo")
  end
  let :workspace do
    user.workspace(workspace_name)
  end
  context "workspaceの初期化" do
    let :workspace do
      user.workspace("#{workspace_name}_create_workspace")
    end

    it ".gitが作成される" do
      workspace.create
      expect(File.exists?("/tmp/store_agent/#{workspace_name}_create_workspace/.git")).to be true
    end
  end
  context "オブジェクトの作成" do
    before do
      if !workspace.exists?
        workspace.create
      end
    end
    let :last_commit_id do
      workspace.version_manager.logs(".").first.objectish
    end

    it "ディレクトリの作成" do
      workspace.directory("create").create
      scoped_commit_id = workspace.version_manager.logs("storage/create").first.objectish
      expect(scoped_commit_id).to eq last_commit_id
    end
    it "ファイルの作成" do
      workspace.file("create_test.txt").create
      scoped_commit_id = workspace.version_manager.logs("storage/create_test.txt").first.objectish
      expect(scoped_commit_id).to eq last_commit_id
    end
    it "ファイルの更新" do
      workspace.file("update_test.txt").create
      workspace.file("update_test.txt").update("updated")
      scoped_commit_id = workspace.version_manager.logs("storage/update_test.txt").first.objectish
      expect(scoped_commit_id).to eq last_commit_id
    end
    it "ディレクトリの削除" do
      workspace.directory("delete").create
      workspace.directory("delete").delete
      scoped_commit_id = workspace.version_manager.logs("storage/delete").first.objectish
      expect(scoped_commit_id).to eq last_commit_id
    end
    it "ファイルの削除" do
      workspace.file("delete_test.txt").create
      workspace.file("delete_test.txt").delete
      scoped_commit_id = workspace.version_manager.logs("storage/delete_test.txt").first.objectish
      expect(scoped_commit_id).to eq last_commit_id
    end
    it "ファイルの更新途中で例外が発生した場合、ロールバックされる" do
      file = workspace.file("rollback_test.txt")
      file.create
      class << file.metadata
        def update(*)
          raise
        end
      end
      last_commit_id
      begin
        file.update("updated")
      rescue
      end
      scoped_commit_id = workspace.version_manager.logs("storage/rollback_test.txt").first.objectish
      expect(scoped_commit_id).to eq last_commit_id
      expect(workspace.file("rollback_test.txt").read).to eq ""
    end
  end
end
