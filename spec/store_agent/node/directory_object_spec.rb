require "spec_helper"

RSpec.describe StoreAgent::Node::DirectoryObject do
  let :user do
    StoreAgent::User.new("foo")
  end
  let :workspace do
    user.workspace(workspace_name)
  end
  before do
    workspace.create if !workspace.exists?
  end

  context "初期化時に path の末尾に / を追加する" do
    let :workspace_name do
      "test_dir_workspace_01"
    end
    let :directory do
      workspace.directory(@path)
    end

    it ". は / に変換される" do
      @path = "."
      expect(directory.path).to eq "/"
    end
    it "/././. は / に変換される" do
      @path = "/././."
      expect(directory.path).to eq "/"
    end
    it "foo は /foo/ に変換される" do
      @path = "foo"
      expect(directory.path).to eq "/foo/"
    end
    it "///foo///bar/// は /foo/bar/ に変換される" do
      @path = "///foo///bar///"
      expect(directory.path).to eq "/foo/bar/"
    end
    it "../foo/bar は /foo/bar/ に変換される" do
      @path = "../foo/bar"
      expect(directory.path).to eq "/foo/bar/"
    end
  end

  context "ディレクトリ作成のテスト" do
    let :workspace_name do
      "test_dir_workspace_02"
    end
    before do
      dir = workspace.directory("/foo")
      if !dir.exists?
        dir.create
        workspace.file("/bar").create
      end
    end

    it "既に同名のディレクトリがある場合、作成できない" do
      expect do
        workspace.directory("/foo").create
      end.to raise_error
    end
    it "既に同名のファイルがある場合、作成できない" do
      expect do
        workspace.directory("/bar").create
      end.to raise_error
    end
    it "ディレクトリ名がメタデータの拡張子で終わる場合、作成できない" do
      expect do
        workspace.directory("/hoge.meta").create
      end.to raise_error
    end
    it "ディレクトリ名がパーミッションデータの拡張子で終わる場合、作成できない" do
      expect do
        workspace.directory("/hoge.perm").create
      end.to raise_error
    end
    it "パスに問題が無ければディレクトリ作成できる" do
      workspace.directory("hoge").create
      expect(workspace.directory("hoge").exists?).to be true
      workspace.directory("fuga").create
      expect(workspace.directory("fuga").exists?).to be true
      workspace.directory(".git").create
      expect(workspace.directory(".git").exists?).to be true
      workspace.directory(".keep").create
      expect(workspace.directory(".keep").exists?).to be true
    end
  end

  context "ディレクトリ削除のテスト" do
    let :workspace_name do
      "test_dir_workspace_03"
    end
    before do
      dir = workspace.directory("/delete_test")
      if dir.exists?
        StoreAgent::Superuser.new.workspace(workspace_name).directory("/delete_test").delete
      end
      workspace.directory("/delete_test").create
      workspace.directory("/delete_test/foo").create
      workspace.file("/delete_test/hoge.txt").create
    end

    context "配下の全オブジェクトに対して削除権限がある場合" do
      before do
        workspace.directory("/delete_test").delete
      end

      it "ルートノードは削除できない" do
        expect do
          workspace.directory("/").delete
        end.to raise_error
      end
      it "ディレクトリが丸ごと削除される" do
        expect(workspace.directory("/delete_test").exists?).to be false
      end
      it "メタデータ側のディレクトリは削除される" do
        metadata_dir_path = "/tmp/store_agent/test_dir_workspace_03/metadata/delete_test"
        expect(File.exists?(metadata_dir_path)).to be false
      end
      it "パーミッション側のディレクトリは削除される" do
        permission_dir_path = "/tmp/store_agent/test_dir_workspace_03/permission/delete_test"
        expect(File.exists?(permission_dir_path)).to be false
      end
    end
    context "配下に削除権限が無いオブジェクトがある場合" do
      let :workspace_name do
        "test_dir_workspace_03_2"
      end
      before do
        workspace.directory("/delete_test/bar").create
        workspace.file("/delete_test/bar/hoge.txt").create("1234567890")
        workspace.file("/delete_test/bar/hoge.txt").permission.unset!("foo", "write")
        workspace.directory("/delete_test/foobar").create
        workspace.file("/delete_test/foobar/fuga.txt").create("12345678901234567890")
        workspace.directory("/delete_test/foobar").permission.unset!("foo", "write")
        begin
          workspace.directory("/delete_test").delete
        rescue
        end
      end

      context "メタデータの中身" do
        context "ルートディレクトリ" do
          let :root_node do
            workspace.directory("/")
          end

          it "ディスク使用量は 4096 * 4 + 30 バイト" do
            expect(root_node.metadata.disk_usage).to eq ((4096 * 4) + 30)
          end
          it "直下のファイル数は 1" do
            expect(root_node.directory_file_count).to eq 1
          end
          it "サブツリー全体の配下ファイル数は 5" do
            expect(root_node.tree_file_count).to eq 5
          end
        end
        context "中間ディレクトリ" do
          let :dir do
            workspace.directory("/delete_test")
          end

          it "ディスク使用量は 4096 * 3 + 30 バイト" do
            expect(dir.metadata.disk_usage).to eq ((4096 * 3) + 30)
          end
          it "直下のファイル数は 2" do
            expect(dir.directory_file_count).to eq 2
          end
          it "サブツリー全体の配下ファイル数は 4" do
            expect(dir.tree_file_count).to eq 4
          end
        end
        context "配下ファイルに削除権限が無いディレクトリ" do
          let :dir do
            workspace.directory("/delete_test/bar")
          end

          it "ディスク使用量は 4096 + 10 バイト" do
            expect(dir.metadata.disk_usage).to eq (4096 + 10)
          end
          it "直下のファイル数は 1" do
            expect(dir.directory_file_count).to eq 1
          end
          it "サブツリー全体の配下ファイル数は 1" do
            expect(dir.tree_file_count).to eq 1
          end
        end
        context "削除権限が無いディレクトリ" do
          let :dir do
            workspace.directory("/delete_test/foobar")
          end

          it "ディスク使用量は 4096 + 20 バイト" do
            expect(dir.metadata.disk_usage).to eq (4096 + 20)
          end
          it "直下のファイル数は 1" do
            expect(dir.directory_file_count).to eq 1
          end
          it "サブツリー全体の配下ファイル数は 1" do
            expect(dir.tree_file_count).to eq 1
          end
        end
      end
      context "削除権限があるノード" do
        it "ディレクトリが丸ごと削除される" do
          expect(workspace.directory("/delete_test/foo").exists?).to be false
        end
        it "メタデータ側のディレクトリは削除される" do
          metadata_dir_path = "/tmp/store_agent/test_dir_workspace_03_2/metadata/delete_test/foo"
          expect(File.exists?(metadata_dir_path)).to be false
        end
        it "パーミッション側のディレクトリは削除される" do
          permission_dir_path = "/tmp/store_agent/test_dir_workspace_03_2/permission/delete_test/foo"
          expect(File.exists?(permission_dir_path)).to be false
        end
      end
      context "サブツリー内に削除権限が無いファイルがある場合" do
        it "ファイルと親ディレクトリは削除されずに残る" do
          expect(workspace.directory("/delete_test/bar").exists?).to be true
          expect(workspace.file("/delete_test/bar/hoge.txt").exists?).to be true
        end
        it "ファイルと親ディレクトリのメタデータは削除されない" do
          dir_metadata_path = "/tmp/store_agent/test_dir_workspace_03_2/metadata/delete_test/bar/.meta"
          file_metadata_path = "/tmp/store_agent/test_dir_workspace_03_2/metadata/delete_test/bar/hoge.txt.meta"
          expect(File.exists?(dir_metadata_path)).to be true
          expect(File.exists?(file_metadata_path)).to be true
        end
        it "ファイルと親ディレクトリのパーミッションは削除されない" do
          dir_permission_path = "/tmp/store_agent/test_dir_workspace_03_2/permission/delete_test/bar/.perm"
          file_permission_path = "/tmp/store_agent/test_dir_workspace_03_2/permission/delete_test/bar/hoge.txt.perm"
          expect(File.exists?(dir_permission_path)).to be true
          expect(File.exists?(file_permission_path)).to be true
        end
      end
      context "サブツリー内に削除権限が無いディレクトリがある場合" do
        it "ディレクトリと配下ファイルは削除されずに残る" do
          expect(workspace.directory("/delete_test/foobar").exists?).to be true
          expect(workspace.file("/delete_test/foobar/fuga.txt").exists?).to be true
        end
        it "ディレクトリと配下ファイルのメタデータは削除されない" do
          dir_metadata_path = "/tmp/store_agent/test_dir_workspace_03_2/metadata/delete_test/foobar/.meta"
          file_metadata_path = "/tmp/store_agent/test_dir_workspace_03_2/metadata/delete_test/foobar/fuga.txt.meta"
          expect(File.exists?(dir_metadata_path)).to be true
          expect(File.exists?(file_metadata_path)).to be true
        end
        it "ディレクトリと配下ファイルのパーミッションは削除されない" do
          dir_permission_path = "/tmp/store_agent/test_dir_workspace_03_2/permission/delete_test/foobar/.perm"
          file_permission_path = "/tmp/store_agent/test_dir_workspace_03_2/permission/delete_test/foobar/fuga.txt.perm"
          expect(File.exists?(dir_permission_path)).to be true
          expect(File.exists?(file_permission_path)).to be true
        end
      end
    end
  end

  context "配下オブジェクトを取得するテスト" do
    let :workspace_name do
      "test_dir_workspace_04"
    end
    let :dir do
      workspace.directory("search_children")
    end
    before do
      if !dir.exists?
        dir.create
        workspace.file("search_children/foo.txt").create
        workspace.directory("search_children/bar").create
      end
    end

    context "ディレクトリを検索する" do
      it "配下に存在するディレクトリを検索する" do
        find_dir = dir.directory("bar")
        expect(find_dir.path).to eq "/search_children/bar/"
        expect(find_dir.exists?).to be true
      end
      it "配下に存在しないディレクトリを検索する" do
        find_dir = dir.directory("foobar")
        expect(find_dir.path).to eq "/search_children/foobar/"
        expect(find_dir.exists?).to be false
      end
      it ". を検索すると、カレントディレクトリが返ってくる" do
        expect(dir.directory(".").path).to eq "/search_children/"
      end
      it "/ を検索すると、カレントディレクトリが返ってくる" do
        expect(dir.directory("/").path).to eq "/search_children/"
      end
      it ".. は / に変換されて検索される" do
        expect(dir.directory("..").path).to eq "/search_children/"
      end
    end
    context "ファイルを検索する" do
      it "配下に存在するファイルを検索する" do
        file = dir.file("foo.txt")
        expect(file.path).to eq "/search_children/foo.txt"
        expect(file.exists?).to be true
      end
      it "配下に存在しないファイルを検索する" do
        file = dir.file("foobar.txt")
        expect(file.path).to eq "/search_children/foobar.txt"
        expect(file.exists?).to be false
      end
      it ".. は / に変換されて検索される" do
        expect(dir.file("../foo.txt").path).to eq "/search_children/foo.txt"
      end
    end
    context "タイプが不明なオブジェクトを検索する" do
      it "パスがディレクトリなら、ディレクトリオブジェクトを返す" do
        expect(dir.find_object("bar").class).to eq StoreAgent::Node::DirectoryObject
      end
      it "パスがファイルなら、ファイルオブジェクトを返す" do
        expect(dir.find_object("foo.txt").class).to eq StoreAgent::Node::FileObject
      end
      it "パスにファイルが存在しない場合、エラーが発生する" do
        expect do
          dir.find_object("foobar.txt")
        end.to raise_error
      end
    end
    context "直下のファイル一覧を取得する" do
      it "ディレクトリの直下にあるファイル一覧を返す" do
        expect(dir.children.map(&:path).sort).to eq ["/search_children/bar/", "/search_children/foo.txt"].sort
      end
    end
  end
end
