#--
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
#++

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
      "test_dir_workspace_initialize"
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
      "test_dir_workspace_create"
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
      "test_dir_workspace_delete"
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
        metadata_dir_path = "/tmp/store_agent/test_dir_workspace_delete/metadata/delete_test"
        expect(File.exists?(metadata_dir_path)).to be false
      end
      it "パーミッション側のディレクトリは削除される" do
        permission_dir_path = "/tmp/store_agent/test_dir_workspace_delete/permission/delete_test"
        expect(File.exists?(permission_dir_path)).to be false
      end
    end
    context "配下に削除権限が無いオブジェクトがある場合" do
      let :workspace_name do
        "test_dir_workspace_delete_with_no_permission"
      end
      before do
        workspace.directory("/delete_test/bar").create
        workspace.file("/delete_test/bar/hoge.txt").create("1234567890")
        workspace.file("/delete_test/bar/hoge.txt").unset_permission(identifier: "foo", permission_names: "write")
        workspace.directory("/delete_test/foobar").create
        workspace.file("/delete_test/foobar/fuga.txt").create("12345678901234567890")
        workspace.directory("/delete_test/foobar").unset_permission(identifier: "foo", permission_names: "write")
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

          it "ディスク使用量は #{$directory_bytesize} * 4 + 30 バイト" do
            expect(root_node.metadata.disk_usage).to eq (($directory_bytesize * 4) + 30)
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

          it "ディスク使用量は #{$directory_bytesize} * 3 + 30 バイト" do
            expect(dir.metadata.disk_usage).to eq (($directory_bytesize * 3) + 30)
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

          it "ディスク使用量は #{$directory_bytesize} + 10 バイト" do
            expect(dir.metadata.disk_usage).to eq ($directory_bytesize + 10)
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

          it "ディスク使用量は #{$directory_bytesize} + 20 バイト" do
            expect(dir.metadata.disk_usage).to eq ($directory_bytesize + 20)
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
          metadata_dir_path = "/tmp/store_agent/test_dir_workspace_delete_with_no_permission/metadata/delete_test/foo"
          expect(File.exists?(metadata_dir_path)).to be false
        end
        it "パーミッション側のディレクトリは削除される" do
          permission_dir_path = "/tmp/store_agent/test_dir_workspace_delete_with_no_permission/permission/delete_test/foo"
          expect(File.exists?(permission_dir_path)).to be false
        end
      end
      context "サブツリー内に削除権限が無いファイルがある場合" do
        it "ファイルと親ディレクトリは削除されずに残る" do
          expect(workspace.directory("/delete_test/bar").exists?).to be true
          expect(workspace.file("/delete_test/bar/hoge.txt").exists?).to be true
        end
        it "ファイルと親ディレクトリのメタデータは削除されない" do
          dir_metadata_path = "/tmp/store_agent/test_dir_workspace_delete_with_no_permission/metadata/delete_test/bar/.meta"
          file_metadata_path = "/tmp/store_agent/test_dir_workspace_delete_with_no_permission/metadata/delete_test/bar/hoge.txt.meta"
          expect(File.exists?(dir_metadata_path)).to be true
          expect(File.exists?(file_metadata_path)).to be true
        end
        it "ファイルと親ディレクトリのパーミッションは削除されない" do
          dir_permission_path = "/tmp/store_agent/test_dir_workspace_delete_with_no_permission/permission/delete_test/bar/.perm"
          file_permission_path = "/tmp/store_agent/test_dir_workspace_delete_with_no_permission/permission/delete_test/bar/hoge.txt.perm"
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
          dir_metadata_path = "/tmp/store_agent/test_dir_workspace_delete_with_no_permission/metadata/delete_test/foobar/.meta"
          file_metadata_path = "/tmp/store_agent/test_dir_workspace_delete_with_no_permission/metadata/delete_test/foobar/fuga.txt.meta"
          expect(File.exists?(dir_metadata_path)).to be true
          expect(File.exists?(file_metadata_path)).to be true
        end
        it "ディレクトリと配下ファイルのパーミッションは削除されない" do
          dir_permission_path = "/tmp/store_agent/test_dir_workspace_delete_with_no_permission/permission/delete_test/foobar/.perm"
          file_permission_path = "/tmp/store_agent/test_dir_workspace_delete_with_no_permission/permission/delete_test/foobar/fuga.txt.perm"
          expect(File.exists?(dir_permission_path)).to be true
          expect(File.exists?(file_permission_path)).to be true
        end
      end
    end
  end

  context "ディレクトリのコピー" do
    let :workspace_name do
      "test_dir_workspace_copy"
    end
    let :src_dir do
      workspace.directory("copy/src")
    end
    before do
      dir = workspace.directory("copy")
      if !dir.exists?
        dir.create
        src_dir.create
        src_dir.file("foo.txt").create("copy")
      end
    end

    context "コピー先にオブジェクトが無い場合" do
      it "ディレクトリが中身ごとコピーされ、メタデータが更新される" do
        dest_path = "copy/dest"

        prev_count = workspace.directory("copy").tree_file_count
        src_dir.copy(dest_path)
        expect(workspace.file("copy/dest/foo.txt").read).to eq "copy"
        expect(workspace.directory("copy").tree_file_count).to eq prev_count + 2
      end
    end
    context "コピー先にファイルが存在する場合" do
      it "例外 InvalidNodeTypeError が発生する" do
        dest_file_path = "copy/dest_file.txt"
        workspace.file(dest_file_path).create("dest file")

        expect do
          src_dir.copy(dest_file_path)
        end.to raise_error StoreAgent::InvalidNodeTypeError
      end
    end
    context "コピー先にディレクトリが存在する場合" do
      it "コピー先のディレクトリ内に同名のオブジェクトが存在しない場合、ディレクトリがコピーされる" do
        dest_directory_path = "copy/dest_dir"
        workspace.directory(dest_directory_path).create

        prev_count = workspace.directory("copy").tree_file_count
        prev_bytesize = workspace.directory("copy").metadata["directory_bytes"]
        src_dir.copy(dest_directory_path)
        expect(workspace.directory(dest_directory_path).file("src/foo.txt").read).to eq "copy"
        expect(workspace.directory("copy").metadata["directory_bytes"]).to eq prev_bytesize + $directory_bytesize + 4
        expect(workspace.directory("copy").tree_file_count).to eq prev_count + 2
      end
      it "コピー先のディレクトリ内に同名のファイルが存在する場合、例外が発生する" do
        dest_directory_path = "copy/dest_exists_file"
        workspace.directory(dest_directory_path).create
        workspace.directory(dest_directory_path).file("src").create("file already exists")

        expect do
          src_dir.copy(dest_directory_path)
        end.to raise_error StoreAgent::InvalidPathError
      end
      it "コピー先のディレクトリ内に同名のディレクトリが存在する場合、例外が発生する" do
        dest_directory_path = "copy/dest_exists_dir"
        workspace.directory(dest_directory_path).create
        workspace.directory(dest_directory_path).directory("src").create

        expect do
          src_dir.copy(dest_directory_path)
        end.to raise_error StoreAgent::InvalidPathError
      end
    end
  end

  context "ディレクトリの移動" do
    let :workspace_name do
      "test_dir_workspace_move"
    end
    let :directory do
      workspace.directory("move")
    end
    let :src_dir do
      workspace.directory("move/src")
    end
    before do
      if !directory.exists?
        directory.create
      end
      if !src_dir.exists?
        src_dir.create
        workspace.file("move/src/bar.txt").create("move")
      end
    end

    context "移動先にオブジェクトが無い場合" do
      it "ディレクトリが中身ごと移動され、メタデータが更新される" do
        dest_path = "move/dest"

        prev_count = workspace.directory("move").tree_file_count
        src_dir.move(dest_path)
        expect(workspace.file("move/dest/bar.txt").read).to eq "move"
        expect(workspace.directory("move").tree_file_count).to eq prev_count
      end
    end
    context "移動先にファイルが存在する場合" do
      it "例外 InvalidNodeTypeError が発生する" do
        dest_file_path = "move/dest_file.txt"
        workspace.file(dest_file_path).create("dest file")

        expect do
          src_dir.move(dest_file_path)
        end.to raise_error StoreAgent::InvalidNodeTypeError
      end
    end
    context "移動先にディレクトリが存在する場合" do
      it "移動先のディレクトリ内に同名のオブジェクトが存在しない場合、ディレクトリが移動される" do
        dest_directory_path = "move/dest_dir"
        workspace.directory(dest_directory_path).create

        prev_count = workspace.directory("move").tree_file_count
        prev_bytesize = workspace.directory("move").metadata["directory_bytes"]
        src_dir.move(dest_directory_path)
        expect(workspace.directory(dest_directory_path).file("src/bar.txt").read).to eq "move"
        expect(workspace.directory("move").metadata["directory_bytes"]).to eq prev_bytesize
        expect(workspace.directory("move").tree_file_count).to eq prev_count
      end
      it "移動先のディレクトリ内に同名のファイルが存在する場合、例外が発生する" do
        dest_directory_path = "move/dest_exists_file"
        workspace.directory(dest_directory_path).create
        workspace.directory(dest_directory_path).file("src").create("file already exists")

        expect do
          src_dir.move(dest_directory_path)
        end.to raise_error StoreAgent::InvalidPathError
      end
      it "移動先のディレクトリ内に同名のディレクトリが存在する場合、例外が発生する" do
        dest_directory_path = "move/dest_exists_dir"
        workspace.directory(dest_directory_path).create
        workspace.directory(dest_directory_path).directory("src").create

        expect do
          src_dir.move(dest_directory_path)
        end.to raise_error StoreAgent::InvalidPathError
      end
    end
  end

  context "メタデータ取得のテスト" do
    let :workspace_name do
      "test_dir_workspace_get_metadata"
    end
    it "get_metadata でメタデータをハッシュ形式で取得できる" do
      expect(workspace.directory("/").get_metadata.class).to eq Hash
    end
  end

  context "パーミッション情報取得のテスト" do
    let :workspace_name do
      "test_dir_workspace_get_permissions"
    end
    it "get_permissions でパーミッション情報をハッシュ形式で取得できる" do
      expect(workspace.directory("/").get_permissions.class).to eq Hash
    end
  end

  context "オーナー変更のテスト" do
    let :workspace_name do
      "test_dir_workspace_chown"
    end
    before do
      if !(dir = workspace.directory("chown")).exists?
        dir.create
        workspace.file("chown/hoge.txt").create
        workspace.directory("chown_r").create
        workspace.file("chown_r/fuga.txt").create
      end
    end
    it "userは権限がないので、オーナー変更できない" do
      expect do
        workspace.directory("chown").chown(identifier: "hoge")
      end.to raise_error
    end
    context "superuserはオーナー変更できる" do
      it "recursive オプションが無いと、指定したディレクトリのみ変更される" do
        superuser = StoreAgent::Superuser.new
        superuser.workspace(workspace_name).directory("chown").chown(identifier: "hoge")
        expect(workspace.directory("chown").metadata["owner"]).to eq "hoge"
        expect(workspace.file("chown/hoge.txt").metadata["owner"]).to eq "foo"
      end
      it "recursive: true にすると、指定したディレクトリ以下の全ファイルが変更される" do
        superuser = StoreAgent::Superuser.new
        superuser.workspace(workspace_name).directory("chown_r").chown(identifier: "hoge", recursive: true)
        expect(workspace.directory("chown_r").metadata["owner"]).to eq "hoge"
        expect(workspace.file("chown_r/fuga.txt").metadata["owner"]).to eq "hoge"
      end
    end
  end

  context "配下オブジェクトを取得するテスト" do
    let :workspace_name do
      "test_dir_workspace_delete"
    end
    let :dir do
      workspace.directory("search_children")
    end
    before do
      if !dir.exists?
        dir.create
        workspace.file("search_children/foo.txt").create
        workspace.directory("search_children/bar").create
        workspace.directory("search_children/symlink_dir").create
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
      it "パスに非対応形式のファイルが存在する場合、例外が発生する" do
        File.symlink("/dev/null", "#{dir.storage_object_path}/symlink_dir/symlink")
        expect do
          dir.find_object("symlink_dir/symlink")
        end.to raise_error
      end
      it "パスにファイルが存在しない場合、仮想オブジェクトを返す" do
        expect(dir.find_object("foobar.txt").class).to eq StoreAgent::Node::VirtualObject
      end
    end
    context "直下のファイル一覧を取得する" do
      it "ディレクトリの直下にあるファイル一覧を返す" do
        expect(dir.children.map(&:path).sort).to eq ["/search_children/bar/", "/search_children/foo.txt", "/search_children/symlink_dir/"].sort
      end
    end
  end
end
