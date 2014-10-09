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
  context "オブジェクトの作成/更新/削除" do
    before do
      if !workspace.exists?
        workspace.create
      end
    end

    it "ディレクトリの作成" do
      workspace.directory("create").create
      scoped_commit_id = workspace.version_manager.revisions("storage/create").first
      expect(scoped_commit_id).to eq workspace.version_manager.revisions.first
    end
    it "ファイルの作成" do
      workspace.file("create_test.txt").create
      scoped_commit_id = workspace.version_manager.revisions("storage/create_test.txt").first
      expect(scoped_commit_id).to eq workspace.version_manager.revisions.first
    end
    it "ファイルの更新" do
      workspace.file("update_test.txt").create
      workspace.file("update_test.txt").update("updated")
      scoped_commit_id = workspace.version_manager.revisions("storage/update_test.txt").first
      expect(scoped_commit_id).to eq workspace.version_manager.revisions.first
    end
    it "ディレクトリの削除" do
      workspace.directory("delete").create
      workspace.directory("delete").delete
      scoped_commit_id = workspace.version_manager.revisions("storage/delete").first
      expect(scoped_commit_id).to eq workspace.version_manager.revisions.first
    end
    it "ファイルの削除" do
      workspace.file("delete_test.txt").create
      workspace.file("delete_test.txt").delete
      scoped_commit_id = workspace.version_manager.revisions("storage/delete_test.txt").first
      expect(scoped_commit_id).to eq workspace.version_manager.revisions.first
    end
    it "ファイルの更新途中で例外が発生した場合、ロールバックされる" do
      file = workspace.file("rollback_test.txt")
      file.create
      class << file.metadata
        def update(*)
          raise
        end
      end
      begin
        file.update("updated")
      rescue
      end
      scoped_commit_id = workspace.version_manager.revisions("storage/rollback_test.txt").first
      expect(scoped_commit_id).to eq workspace.version_manager.revisions.first
      expect(workspace.file("rollback_test.txt").read).to eq ""
    end
    it ".gitignore が作成されても、その中身はファイルのバージョン管理時には無視される" do
      workspace.file(".gitignore").create("*\n")
      workspace.directory("ignore").create
      scoped_commit_id = workspace.version_manager.revisions("storage/ignore").first
      expect(scoped_commit_id).to eq workspace.version_manager.revisions.first
      workspace.file("ignore/tmp.txt").create
      scoped_commit_id = workspace.version_manager.revisions("storage/ignore/tmp.txt").first
      expect(scoped_commit_id).to eq workspace.version_manager.revisions.first
    end
  end
  context "予約されているファイル/ディレクトリ名は作成できない" do
    let :workspace do
      user.workspace("#{workspace_name}_reserved_name")
    end
    before do
      if !workspace.exists?
        workspace.create
      end
    end

    it "名前が .git のディレクトリ" do
      begin
        workspace.directory(".git").create
      rescue
      end
      expect(workspace.directory(".git").exists?).to be false
    end
    it "名前が .git のファイル" do
      begin
        workspace.file(".git").create
      rescue
      end
      expect(workspace.file(".git").exists?).to be false
    end
    it "名前が .keep のディレクトリ" do
      expect do
        workspace.directory(".keep").create
      end.to raise_error(StoreAgent::InvalidPathError)
    end
    it "名前が .keep のファイル" do
      expect do
        workspace.file(".keep").create
      end.to raise_error(StoreAgent::InvalidPathError)
    end
  end
end
