require "spec_helper"

RSpec.describe StoreAgent::Node::Metadata do
  let :super_user do
    StoreAgent::Superuser.new
  end
  let :owner do
    StoreAgent::User.new("group", "owner")
  end
  let :namespaced_user do
    StoreAgent::User.new(["user_id", "namespaced_id"])
  end
  let :workspace do
    owner.workspace(workspace_name)
  end

  context "Workspace 作成直後のメタデータ" do
    let :workspace_name do
      "test_workspace_01"
    end
    before do
      workspace.create if !workspace.exists?
      @root_node = workspace.directory("/")
    end

    it "JSON形式で保存される" do
      expect(open(@root_node.metadata.file_path).read).to eq @root_node.metadata.inspect
    end
    it "ルートディレクトリの使用容量は 4096 バイト" do
      expect(@root_node.metadata.disk_usage).to eq 4096
    end
  end

  context "ID が配列のユーザーで Workspace を作成した場合" do
    it "owner は配列の先頭要素が適用される" do
      namespaced_workspace = namespaced_user.workspace("test_workspace_namespaced_id")
      namespaced_workspace.create
      root_node = namespaced_workspace.root
      expect(root_node.metadata["owner"]).to eq "user_id"
    end
  end

  context "Workspace にディレクトリを作成した場合のメタデータ" do
    let :workspace_name do
      "test_workspace_02"
    end
    before do
      if !workspace.exists?
        workspace.create
        owner.workspace(workspace_name).directory("foo").create
        owner.workspace(workspace_name).directory("foo/bar").create
      end
      @root_node = workspace.directory("/")
      @dir_1 = owner.workspace(workspace_name).directory("foo")
      @dir_2 = owner.workspace(workspace_name).directory("foo/bar")
    end

    context "ルートディレクトリ" do
      it "ディスク使用量は (4096 * 3) バイト" do
        expect(@root_node.metadata.disk_usage).to eq (4096 * 3)
      end
      it "直下のファイル数は 1" do
        expect(@root_node.directory_file_count).to eq 1
      end
      it "サブツリー全体の配下ファイル数は 2" do
        expect(@root_node.tree_file_count).to eq 2
      end
    end
    context "中間ディレクトリ" do
      it "ディスク使用量は (4096 * 2) バイト" do
        expect(@dir_1.metadata.disk_usage).to eq (4096 * 2)
      end
      it "直下のファイル数は 1" do
        expect(@dir_1.directory_file_count).to eq 1
      end
      it "サブツリー全体の配下ファイル数は 1" do
        expect(@dir_1.tree_file_count).to eq 1
      end
    end
    context "最下層のディレクトリ" do
      it "ディスク使用量は 4096 バイト" do
        expect(@dir_2.metadata.disk_usage).to eq 4096
      end
      it "直下のファイル数は 0" do
        expect(@dir_2.directory_file_count).to eq 0
      end
      it "サブツリー全体の配下ファイル数は 0" do
        expect(@dir_2.tree_file_count).to eq 0
      end
    end
  end

  context "Workspace にディレクトリとファイルを作成した場合のメタデータ" do
    let :workspace_name do
      "test_workspace_03"
    end
    before do
      if !workspace.exists?
        workspace.create
        owner.workspace(workspace_name).directory("foo").create
        owner.workspace(workspace_name).file("foo/bar.txt").create("body" => "1234567890")
      end
      @root_node = workspace.directory("/")
      @dir = owner.workspace(workspace_name).directory("foo")
      @file = owner.workspace(workspace_name).file("foo/bar.txt")
    end

    context "ルートディレクトリ" do
      it "ディスク使用量は (4096 * 2) + 10 バイト" do
        expect(@root_node.metadata.disk_usage).to eq ((4096 * 2) + 10)
      end
      it "直下のファイル数は 1" do
        expect(@root_node.directory_file_count).to eq 1
      end
      it "サブツリー全体の配下ファイル数は 2" do
        expect(@root_node.tree_file_count).to eq 2
      end
    end
    context "ディレクトリ" do
      it "ディスク使用量は 4096 + 10 バイト" do
        expect(@dir.metadata.disk_usage).to eq (4096 + 10)
      end
      it "直下のファイル数は 1" do
        expect(@dir.directory_file_count).to eq 1
      end
      it "サブツリー全体の配下ファイル数は 1" do
        expect(@dir.tree_file_count).to eq 1
      end
    end
    context "ファイル" do
      it "ディスク使用量は 10 バイト" do
        expect(@file.metadata.disk_usage).to eq 10
      end
      it "ディレクトリではないので、配下のファイルは存在しない" do
        expect do
          @file.directory_file_count
        end.to raise_error
        expect do
          @file.tree_file_count
        end.to raise_error
      end
    end
  end

  context "ファイルの中身を更新した場合のメタデータ" do
    let :workspace_name do
      "test_workspace_04"
    end
    before do
      if !workspace.exists?
        workspace.create
        owner.workspace(workspace_name).directory("foo").create
        owner.workspace(workspace_name).file("foo/bar.txt").create("body" => "1234567890")
        owner.workspace(workspace_name).file("foo/bar.txt").update("body" => "updated")
      end
      @root_node = workspace.directory("/")
      @dir = owner.workspace(workspace_name).directory("foo")
      @file = owner.workspace(workspace_name).file("foo/bar.txt")
    end

    context "ルートディレクトリ" do
      it "ディスク使用量は (4096 * 2) + 7 バイト" do
        expect(@root_node.metadata.disk_usage).to eq ((4096 * 2) + 7)
      end
      it "直下のファイル数は 1" do
        expect(@root_node.directory_file_count).to eq 1
      end
      it "サブツリー全体の配下ファイル数は 2" do
        expect(@root_node.tree_file_count).to eq 2
      end
    end
    context "ディレクトリ" do
      it "ディスク使用量は 4096 + 7 バイト" do
        expect(@dir.metadata.disk_usage).to eq (4096 + 7)
      end
      it "直下のファイル数は 1" do
        expect(@dir.directory_file_count).to eq 1
      end
      it "サブツリー全体の配下ファイル数は 1" do
        expect(@dir.tree_file_count).to eq 1
      end
    end
    context "ファイル" do
      it "ディスク使用量は 7 バイト" do
        expect(@file.metadata.disk_usage).to eq 7
      end
      it "ディレクトリではないので、配下のファイルは存在しない" do
        expect do
          @file.directory_file_count
        end.to raise_error
        expect do
          @file.tree_file_count
        end.to raise_error
      end
    end
  end

  context "ファイルを削除した場合のメタデータ" do
    let :workspace_name do
      "test_workspace_05"
    end
    before do
      if !workspace.exists?
        workspace.create
        owner.workspace(workspace_name).directory("foo").create
        owner.workspace(workspace_name).file("foo/bar.txt").create("body" => "1234567890")
        owner.workspace(workspace_name).file("foo/foobar.txt").create("body" => "0987654321")
        owner.workspace(workspace_name).file("foo/foobar.txt").delete
      end
      @root_node = workspace.directory("/")
      @dir = owner.workspace(workspace_name).directory("foo")
    end

    context "ルートディレクトリ" do
      it "ディスク使用量は (4096 * 2) + 10 バイト" do
        expect(@root_node.metadata.disk_usage).to eq ((4096 * 2) + 10)
      end
      it "直下のファイル数は 1" do
        expect(@root_node.directory_file_count).to eq 1
      end
      it "サブツリー全体の配下ファイル数は 2" do
        expect(@root_node.tree_file_count).to eq 2
      end
    end
    context "ディレクトリ" do
      it "ディスク使用量は 4096 + 10 バイト" do
        expect(@dir.metadata.disk_usage).to eq (4096 + 10)
      end
      it "直下のファイル数は 1" do
        expect(@dir.directory_file_count).to eq 1
      end
      it "サブツリー全体の配下ファイル数は 1" do
        expect(@dir.tree_file_count).to eq 1
      end
      it "ファイルの中身を変更後に保存しないで削除した場合、変更前の情報が使用される" do
        file = owner.workspace(workspace_name).file("foo/foobarhoge.txt").create("body" => "0987654321")
        file.body = ""
        file.delete
        expect(@dir.metadata.disk_usage).to eq (4096 + 10)
      end
    end
  end

  context "空ディレクトリを削除した場合のメタデータ" do
    let :workspace_name do
      "test_workspace_06"
    end
    before do
      if !workspace.exists?
        workspace.create
        owner.workspace(workspace_name).directory("foo").create
        owner.workspace(workspace_name).directory("foo/bar").create
        owner.workspace(workspace_name).directory("foo/bar").delete
      end
      @root_node = workspace.directory("/")
      @dir = owner.workspace(workspace_name).directory("foo")
    end

    context "ルートディレクトリ" do
      it "ディスク使用量は 4096 * 2 バイト" do
        expect(@root_node.metadata.disk_usage).to eq (4096 * 2)
      end
      it "直下のファイル数は 1" do
        expect(@root_node.directory_file_count).to eq 1
      end
      it "サブツリー全体の配下ファイル数は 1" do
        expect(@root_node.tree_file_count).to eq 1
      end
    end
    context "ディレクトリ" do
      it "ディスク使用量は 4096 バイト" do
        expect(@dir.metadata.disk_usage).to eq 4096
      end
      it "直下のファイル数は 0" do
        expect(@dir.directory_file_count).to eq 0
      end
      it "サブツリー全体の配下ファイル数は 0" do
        expect(@dir.tree_file_count).to eq 0
      end
    end
  end

  context "中身があるディレクトリを削除した場合のメタデータ" do
    let :workspace_name do
      "test_workspace_07"
    end
    before do
      if !workspace.exists?
        workspace.create
        owner.workspace(workspace_name).directory("foo").create
        owner.workspace(workspace_name).directory("foo/bar").create
        owner.workspace(workspace_name).file("foo/bar/hoge.txt").create("1234567890")
        owner.workspace(workspace_name).file("foo/bar/fuga.txt").create("12345")
        owner.workspace(workspace_name).directory("foo/bar").delete
      end
      @root_node = workspace.directory("/")
      @dir = owner.workspace(workspace_name).directory("foo")
    end

    context "ルートディレクトリ" do
      it "ディスク使用量は 4096 * 2 バイト" do
        expect(@root_node.metadata.disk_usage).to eq (4096 * 2)
      end
      it "直下のファイル数は 1" do
        expect(@root_node.directory_file_count).to eq 1
      end
      it "サブツリー全体の配下ファイル数は 1" do
        expect(@root_node.tree_file_count).to eq 1
      end
    end
    context "ディレクトリ" do
      it "ディスク使用量は 4096 バイト" do
        expect(@dir.metadata.disk_usage).to eq 4096
      end
      it "直下のファイル数は 0" do
        expect(@dir.directory_file_count).to eq 0
      end
      it "サブツリー全体の配下ファイル数は 0" do
        expect(@dir.tree_file_count).to eq 0
      end
    end
  end
end
