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

RSpec.describe StoreAgent::Node::PathValidator do
  let :user do
    StoreAgent::User.new("foo")
  end
  let :workspace do
    user.workspace("test_path_validator")
  end
  before :all do
    workspace = StoreAgent::User.new("foo").workspace("test_path_validator")
    workspace.create
    workspace.directory("create").create
    workspace.file("create/tmp.txt").create
    workspace.directory("read").create
    workspace.file("read/foo.txt").create("foo")
    workspace.directory("update").create
    workspace.file("update/bar.txt").create{|f| f.body = "bar"}
    workspace.directory("delete").create
    workspace.directory("delete/hoge/").create
    workspace.file("delete/fuga.txt").create(:fuga)
  end

  context "create時のオブジェクト存在チェック" do
    it "既にオブジェクトが存在する場合、ディレクトリ作成はエラーになる" do
      expect do
        workspace.directory("/create").create
      end.to raise_error(StoreAgent::InvalidPathError)
      expect do
        workspace.directory("/create/tmp.txt").create
      end.to raise_error
    end
    it "既にオブジェクトが存在する場合、ファイル作成はエラーになる" do
      expect do
        workspace.file("/create").create
      end.to raise_error
      expect do
        workspace.file("/create/tmp.txt").create
      end.to raise_error
    end
    it "オブジェクトが存在しなければ、ディレクトリ作成できる" do
      workspace.directory("/create/new_dir").create
      expect(workspace.directory("/create/new_dir").exists?).to be true
    end
    it "オブジェクトが存在しなければ、ファイル作成できる" do
      workspace.file("/create/new_file.txt").create
      expect(workspace.file("/create/new_file.txt").exists?).to be true
    end
  end
  context "read時のオブジェクト存在チェック" do
    it "存在しないオブジェクトの読み込みはエラーになる" do
      expect do
        workspace.directory("/read/foo/bar").read
      end.to raise_error
      expect do
        workspace.file("/read/foo.bar.txt").read
      end.to raise_error
    end
    it "存在するディレクトリは読み込める" do
      expect do
        workspace.directory("read").read
      end.to_not raise_error
    end
    it "存在するファイルは読み込める" do
      expect(workspace.file("read/foo.txt").read).to eq "foo"
    end
  end
  context "update時のオブジェクト存在チェック" do
    it "ディレクトリの更新はエラーになる" do
      expect do
        workspace.directory("/update").update
      end.to raise_error
      expect do
        workspace.directory("/update/foo/bar").update
      end.to raise_error
    end
    it "存在するファイルは更新できる" do
      workspace.file("update/bar.txt").update("body")
      expect(workspace.file("update/bar.txt").read).to eq "body"
    end
    it "存在しないファイルの更新はエラーになる" do
      expect do
        workspace.file("/update/foo.bar.txt").update("foobar")
      end.to raise_error
    end
  end
  context "delete時のオブジェクト存在チェック" do
    it "存在しないオブジェクトを削除しようとするとエラーになる" do
      expect do
        workspace.directory("/delete/foo/bar").delete
      end.to raise_error
      expect do
        workspace.file("/delete/foo/bar.txt").delete
      end.to raise_error
    end
    it "ディレクトリが存在すれば削除できる" do
      workspace.directory("delete/hoge/").delete
      expect(workspace.directory("delete/hoge/").exists?).to be false
    end
    it "ファイルが存在すれば削除できる" do
      workspace.file("delete/fuga.txt").delete
      expect(workspace.file("delete/fuga.txt").exists?).to be false
    end
  end
end
