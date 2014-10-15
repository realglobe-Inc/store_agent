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
  context "予約されているファイル/ディレクトリ名は操作できない" do
    let :workspace do
      user.workspace("#{workspace_name}_reserved_name")
    end
    before do
      if !workspace.exists?
        workspace.create
      end
    end

    context "create できない" do
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
    context "read できない" do
      it "名前が .git のディレクトリ" do
        expect do
          workspace.directory(".git").read
        end.to raise_error(StoreAgent::InvalidPathError)
      end
    end
    context "update できない" do
      it "名前が .keep のファイル" do
        expect do
          workspace.file(".keep").update("keep it")
        end.to raise_error(StoreAgent::InvalidPathError)
      end
    end
    context "delete できない" do
      it "名前が .git のディレクトリ" do
        expect do
          workspace.directory(".git").delete
        end.to raise_error(StoreAgent::InvalidPathError)
      end
    end
  end
  context "過去のオブジェクトの取得" do
    before do
      if !workspace.exists?
        workspace.create
      end
      if !(dir = workspace.directory("revision")).exists?
        dir.create
      end
    end

    it "適切なバージョンを指定すれば、変更前のディレクトリのファイル一覧が取得できる" do
      workspace.directory("revision/delete").create
      workspace.directory("revision/delete/tmp").create
      revision = workspace.version_manager.revisions.first
      workspace.directory("revision/delete/tmp").delete
      expect(workspace.directory("revision/delete").read(revision: revision)).to eq ["tmp"]
    end
    it "適切なバージョンを指定すれば、変更前のファイルが取得できる" do
      workspace.file("revision/update.txt").create("hoge")
      revision = workspace.version_manager.revisions.first
      workspace.file("revision/update.txt").update("fuga")
      expect(workspace.file("revision/update.txt").read(revision: revision)).to eq "hoge"
    end
  end
  context "パーミッションの変更がバージョン管理されている" do
    let :workspace do
      user.workspace("#{workspace_name}_permission")
    end
    before do
      if !workspace.exists?
        workspace.create
      end
    end

    it "パーミッションの設定後にコミットされる" do
      workspace.directory("set").create
      workspace.file("set/foo.txt").create
      revision = workspace.version_manager.revisions.first
      workspace.file("set/foo.txt").set_permission(identifier: "foo", permission_values: {write: false})
      expect(workspace.version_manager.revisions.first).to_not eq revision
    end
    it "パーミッションの設定解除後にコミットされる" do
      workspace.directory("unset").create
      workspace.file("unset/bar.txt").create
      revision = workspace.version_manager.revisions.first
      workspace.file("unset/bar.txt").unset_permission(identifier: "foo", permission_names: ["read", "write"])
      expect(workspace.version_manager.revisions.first).to_not eq revision
    end
  end
  context "オブジェクトのコピー/移動" do
    let :workspace do
      user.workspace("#{workspace_name}_copy_and_move")
    end
    before do
      if !workspace.exists?
        workspace.create
        workspace.directory("copy_dir").create
        workspace.directory("copy_file").create
        workspace.directory("copy_file_dest").create
        workspace.directory("move_dir").create
        workspace.directory("move_file").create
        workspace.directory("move_file_dest").create
      end
    end

    it "ファイルのコピー" do
      workspace.file("copy_file/src.txt").create("copy")
      workspace.file("copy_file/src.txt").copy("copy_file_dest/dest.txt")
      expect(workspace.file("copy_file/src.txt").read).to eq "copy"
      expect(workspace.directory("copy_file").directory_file_count).to eq 1
      expect(workspace.directory("copy_file_dest").directory_file_count).to eq 1
    end
    it "ファイルの移動" do
      workspace.file("move_file/src.txt").create("move")
      workspace.file("move_file/src.txt").move("move_file_dest/dest.txt")
      expect(workspace.file("move_file_dest/dest.txt").read).to eq "move"
      expect(workspace.directory("move_file").directory_file_count).to eq 0
      expect(workspace.directory("move_file_dest").directory_file_count).to eq 1
    end
    it "ディレクトリのコピー" do
      workspace.directory("copy_dir/src_dir").create
      workspace.file("copy_dir/src_dir/foo.txt").create("copy")
      workspace.directory("copy_dir/dest_dir").create
      workspace.directory("copy_dir/src_dir").copy("copy_dir/dest_dir")
      expect(workspace.file("copy_dir/dest_dir/src_dir/foo.txt").read).to eq "copy"
      expect(workspace.directory("copy_dir/src_dir").directory_file_count).to eq 1
      expect(workspace.directory("copy_dir/dest_dir").tree_file_count).to eq 2
    end
    it "ディレクトリの移動" do
      workspace.directory("move_dir/src_dir").create
      workspace.file("move_dir/src_dir/bar.txt").create("move")
      workspace.directory("move_dir/src_dir").move("move_dir/dest_dir")
      expect(workspace.file("move_dir/dest_dir/bar.txt").read).to eq "move"
      expect(workspace.directory("move_dir/src_dir").exists?).to be false
      expect(workspace.directory("move_dir/dest_dir").tree_file_count).to eq 1
    end
  end
end
