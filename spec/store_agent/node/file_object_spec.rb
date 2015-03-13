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
        expect(workspace.file("foo.txt").file?).to eq true
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
    let :src_file do
      workspace.file("copy/src.txt")
    end
    before do
      if !directory.exists?
        directory.create
        src_file.create("copy")
      end
    end

    context "コピー先にオブジェクトが無い場合" do
      it "コピー先にファイルが作成され、メタデータが更新される" do
        dest_create_path = "copy/dest_create.txt"

        prev_count = workspace.directory("copy").directory_file_count
        src_file.copy(dest_create_path)
        expect(workspace.file(dest_create_path).read).to eq "copy"
        expect(workspace.directory("copy").directory_file_count).to eq prev_count + 1
      end
    end
    context "コピー先にファイルが存在する場合" do
      it "コピー先のファイルが上書きされ、メタデータが更新される" do
        dest_update_path = "copy/dest_update.txt"
        workspace.file(dest_update_path).create("dest update file")

        prev_count = workspace.directory("copy").directory_file_count
        prev_bytesize = workspace.file(dest_update_path).metadata["bytes"]
        src_file.copy(dest_update_path)
        expect(workspace.file(dest_update_path).read).to eq "copy"
        expect(workspace.file(dest_update_path).metadata["bytes"]).to eq 4
        expect(workspace.directory("copy").directory_file_count).to eq prev_count
      end
    end
    context "コピー先にディレクトリが存在する場合" do
      it "コピー先のディレクトリ内に同名のオブジェクトが存在しない場合、ファイルが作成される" do
        dest_directory_path = "copy/dest_dir"
        workspace.directory(dest_directory_path).create

        prev_count = workspace.directory(dest_directory_path).directory_file_count
        prev_bytesize = workspace.directory(dest_directory_path).metadata["directory_bytes"]
        src_file.copy(dest_directory_path)
        expect(workspace.directory(dest_directory_path).file("src.txt").read).to eq "copy"
        expect(workspace.directory(dest_directory_path).metadata["directory_bytes"]).to eq prev_bytesize + 4
        expect(workspace.directory(dest_directory_path).directory_file_count).to eq prev_count + 1
      end
      it "コピー先のディレクトリ内に同名のファイルが存在する場合、そのファイルが上書きされる" do
        dest_directory_path = "copy/dest_exists_file"
        workspace.directory(dest_directory_path).create
        workspace.directory(dest_directory_path).file("src.txt").create("file already exists")

        prev_count = workspace.directory(dest_directory_path).directory_file_count
        prev_bytesize = workspace.directory(dest_directory_path).metadata["directory_bytes"]
        src_file.copy(dest_directory_path)
        expect(workspace.directory(dest_directory_path).file("src.txt").read).to eq "copy"
        expect(workspace.directory(dest_directory_path).metadata["directory_bytes"]).to eq prev_bytesize - 15
        expect(workspace.directory(dest_directory_path).directory_file_count).to eq prev_count
      end
      it "コピー先のディレクトリ内に同名のディレクトリが存在する場合、例外が発生する" do
        dest_directory_path = "copy/dest_exists_dir"
        workspace.directory(dest_directory_path).create
        workspace.directory(dest_directory_path).directory("src.txt").create

        expect do
          src_file.copy(dest_directory_path)
        end.to raise_error StoreAgent::InvalidNodeTypeError
      end
    end
  end

  context "ファイルの移動" do
    let :directory do
      workspace.directory("move")
    end
    let :src_file do
      workspace.file("move/src.txt")
    end
    before do
      if !directory.exists?
        directory.create
      end
      if !src_file.exists?
        src_file.create("move")
      end
    end

    context "移動先にオブジェクトが無い場合" do
      it "移動先にファイルが作成され、メタデータが更新される" do
        dest_create_path = "move/dest_create.txt"
        prev_count = workspace.directory("move").directory_file_count
        prev_bytesize = workspace.directory("move").metadata["bytes"]
        src_file.move(dest_create_path)
        expect(workspace.file(dest_create_path).read).to eq "move"
        expect(workspace.directory("move").metadata["bytes"]).to eq prev_bytesize
        expect(workspace.directory("move").directory_file_count).to eq prev_count
      end
    end
    context "移動先にファイルが存在する場合" do
      it "移動先のファイルが上書きされ、メタデータが更新される" do
        dest_update_path = "move/dest_update.txt"
        workspace.file(dest_update_path).create("dest update file")
        prev_count = workspace.directory("move").directory_file_count
        prev_bytesize = workspace.file(dest_update_path).metadata["bytes"]
        src_file.move(dest_update_path)
        expect(workspace.file(dest_update_path).read).to eq "move"
        expect(workspace.file(dest_update_path).metadata["bytes"]).to eq 4
        expect(workspace.directory("move").directory_file_count).to eq prev_count - 1
      end
    end
    context "移動先にディレクトリが存在する場合" do
      it "移動先のディレクトリ内に同名のオブジェクトが存在しない場合、ファイルが作成される" do
        dest_directory_path = "move/dest_dir"
        workspace.directory(dest_directory_path).create

        prev_count = workspace.directory(dest_directory_path).directory_file_count
        prev_bytesize = workspace.directory(dest_directory_path).metadata["directory_bytes"]
        src_file.move(dest_directory_path)
        expect(workspace.directory(dest_directory_path).file("src.txt").read).to eq "move"
        expect(workspace.directory(dest_directory_path).metadata["directory_bytes"]).to eq prev_bytesize + 4
        expect(workspace.directory(dest_directory_path).directory_file_count).to eq prev_count + 1
      end
      it "移動先のディレクトリ内に同名のファイルが存在する場合、そのファイルが上書きされる" do
        dest_directory_path = "move/dest_exists_file"
        workspace.directory(dest_directory_path).create
        workspace.directory(dest_directory_path).file("src.txt").create("file already exists")

        prev_count = workspace.directory(dest_directory_path).directory_file_count
        prev_bytesize = workspace.directory(dest_directory_path).metadata["directory_bytes"]
        src_file.move(dest_directory_path)
        expect(workspace.directory(dest_directory_path).file("src.txt").read).to eq "move"
        expect(workspace.directory(dest_directory_path).metadata["directory_bytes"]).to eq prev_bytesize - 15
        expect(workspace.directory(dest_directory_path).directory_file_count).to eq prev_count
      end
      it "移動先のディレクトリ内に同名のディレクトリが存在する場合、例外が発生する" do
        dest_directory_path = "move/dest_exists_dir"
        workspace.directory(dest_directory_path).create
        workspace.directory(dest_directory_path).directory("src.txt").create

        expect do
          src_file.move(dest_directory_path)
        end.to raise_error StoreAgent::InvalidNodeTypeError
      end
    end
  end
end
