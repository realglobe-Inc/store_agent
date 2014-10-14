require "spec_helper"

RSpec.describe StoreAgent::Node::FileObject do
  let :user do
    StoreAgent::User.new("foo", "bar")
  end
  let :workspace do
    user.workspace("test_file_workspace")
  end
  before do
    workspace.create if !workspace.exists?
  end

  context "ファイル作成のテスト" do
    context "引数が無い場合" do
      it "空のファイルが作成される" do
        workspace.file("foo.txt").create
        expect(workspace.file("foo.txt").read).to eq ""
      end
    end
    context "引数に文字列を渡す場合" do
      it "ファイルの中身はその文字列になる" do
        workspace.file("bar.txt").create("bar")
        expect(workspace.file("bar.txt").read).to eq "bar"
      end
    end
    context "引数にハッシュを渡す場合" do
      it "body パラメータがファイルの中身になる" do
        workspace.file(".git").create("body" => "hoge")
        expect(workspace.file(".git").read).to eq "hoge"
      end
      it "body パラメータはシンボルでも良い" do
        workspace.file(".keep").create(body: "fuga")
        expect(workspace.file(".keep").read).to eq "fuga"
      end
    end
    context "引数にブロックを渡す場合" do
      it "ファイルの中身は、ブロック内で body に設定した値になる" do
        workspace.file("foobar.txt").create do |f|
          f.body = "foobar"
        end
        expect(workspace.file("foobar.txt").read).to eq "foobar"
      end
    end
    context "作成失敗するケース" do
      it "既に同名のディレクトリがある場合、作成できない" do
        workspace.directory("/foo").create
        expect do
          workspace.file("foo").create
        end.to raise_error
      end
      it "既に同名のファイルがある場合、作成できない" do
        workspace.file("hogefuga.txt").create
        expect do
          workspace.directory("hogefuga.txt").create
        end.to raise_error
      end
      it "ファイル名がメタデータの拡張子で終わる場合、作成できない" do
        expect do
          workspace.file("hoge.meta").create
        end.to raise_error
      end
      it "ファイル名がパーミッションデータの拡張子で終わる場合、作成できない" do
        expect do
          workspace.file("hoge.perm").create
        end.to raise_error
      end
    end
  end

  context "ファイル更新のテスト" do
    before do
      file = workspace.file("update_test.txt")
      if !file.exists?
        file.create("1234567890")
      end
    end

    context "引数が無い場合" do
      it "エラーになる" do
        expect do
          workspace.file("update_test.txt").update
        end.to raise_error
      end
    end
    context "引数に文字列を渡す場合" do
      it "ファイルの中身はその文字列になる" do
        workspace.file("update_test.txt").update("update_01")
        expect(workspace.file("update_test.txt").read).to eq "update_01"
      end
    end
    context "引数にハッシュを渡す場合" do
      it "body パラメータがファイルの中身になる" do
        workspace.file("update_test.txt").update("update_02")
        expect(workspace.file("update_test.txt").read).to eq "update_02"
      end
      it "body パラメータはシンボルでも良い" do
        workspace.file("update_test.txt").update("update_03")
        expect(workspace.file("update_test.txt").read).to eq "update_03"
      end
    end
    context "引数にブロックを渡す場合" do
      it "ファイルの中身は、ブロック内で body に設定した値になる" do
        workspace.file("update_test.txt").update do |f|
          f.body = "update_04"
        end
        expect(workspace.file("update_test.txt").read).to eq "update_04"
      end
    end
  end

  context "ファイル削除のテスト" do
    before do
      file = workspace.file("delete_test.txt")
      if !file.exists?
        file.create
      end
    end

    context "削除権限がある場合" do
      before do
        workspace.file("delete_test.txt").delete
      end

      it "ファイルが削除される" do
        expect(workspace.file("delete_test.txt").exists?).to be false
      end
      it "メタデータファイルが削除される" do
        expect(File.exists?(workspace.file("delete_test.txt").metadata.file_path)).to be false
      end
      it "パーミッションファイルが削除される" do
        expect(File.exists?(workspace.file("delete_test.txt").permission.file_path)).to be false
      end
    end
    context "削除権限が無い場合" do
      before do
        begin
          StoreAgent::User.new.workspace("test_file_workspace").file("delete_test.txt").delete
        rescue
        end
      end

      it "ファイルは削除されない" do
        expect(workspace.file("delete_test.txt").exists?).to be true
      end
      it "メタデータファイルは削除されない" do
      end
      it "パーミッションファイルは削除されない" do
      end
    end
  end

  context "メタデータ取得のテスト" do
    it "get_metadata でメタデータをハッシュ形式で取得できる" do
      workspace.file("get_metadata.txt").create
      expect(workspace.file("get_metadata.txt").get_metadata.class).to eq Hash
    end
  end

  context "パーミッション情報取得のテスト" do
    it "get_permissions でパーミッション情報をハッシュ形式で取得できる" do
      workspace.file("get_permissions.txt").create
      expect(workspace.file("get_permissions.txt").get_permissions.class).to eq Hash
    end
  end

  context "オーナー変更のテスト" do
    before do
      if !(file = workspace.file("chown.txt")).exists?
        file.create
      end
    end
    it "userは権限がないので、オーナー変更できない" do
      expect do
        workspace.file("chown.txt").chown(identifier: "hoge")
      end.to raise_error
    end
    it "superuserはオーナー変更できる" do
      superuser = StoreAgent::Superuser.new
      superuser.workspace("test_file_workspace").file("chown.txt").chown(identifier: "hoge")
      expect(workspace.file("chown.txt").metadata["owner"]).to eq "hoge"
    end
  end

  context "配下オブジェクトを取得しようとする" do
    let :file do
      workspace.file("search_children.txt")
    end
    before do
      if !file.exists?
        file.create
      end
    end

    it "ディレクトリを取得しようとするとエラーになる" do
      expect do
        file.directory("hoge")
      end.to raise_error
    end
    it "ファイルを取得しようとするとエラーになる" do
      expect do
        file.file("hoge.txt")
      end.to raise_error
    end
    it "タイプが不明なオブジェクトを取得しようとするとエラーになる" do
      expect do
        file.find_object("hoge")
      end.to raise_error
    end
    it "直下のファイル一覧を取得しようとすると、空の配列が返ってくる" do
      expect(file.children).to eq []
    end
  end

  context "ファイルのコピー" do
    let :directory do
      workspace.directory("copy")
    end
    let :file do
      workspace.file("copy/src.txt")
    end
    let :dest_path do
      "copy/dest.txt"
    end
    before do
      if !directory.exists?
        directory.create
        file.create("copy")
        workspace.file("copy/src.txt").copy(dest_path)
      end
    end

    it "コピー先にファイルが作成される" do
      expect(workspace.file(dest_path).read).to eq "copy"
    end
    it "メタデータが更新される" do
      expect(workspace.directory("copy").directory_file_count).to eq 2
    end
  end

  context "ファイルの移動" do
    let :directory do
      workspace.directory("move")
    end
    let :file do
      workspace.file("move/src.txt")
    end
    let :dest_path do
      "move_dest/dest.txt"
    end
    before do
      if !directory.exists?
        directory.create
        workspace.directory("move_dest").create
        file.create("move")
        workspace.file("move/src.txt").move(dest_path)
      end
    end

    it "移動先にファイルが作成される" do
      expect(workspace.file(dest_path).read).to eq "move"
    end
    it "メタデータが更新される" do
      expect(workspace.directory("move").directory_file_count).to eq 0
      expect(workspace.directory("move_dest").directory_file_count).to eq 1
    end
  end
end
