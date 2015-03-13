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

RSpec.describe StoreAgent::Node::Locker do
  let :user do
    StoreAgent::User.new("foo")
  end
  let :workspace do
    user.workspace("test_lock")
  end
  before do
    skip "時間かかるのでスキップ"
  end
  before :all do
    workspace = StoreAgent::User.new("foo").workspace("test_lock")
    workspace.create
    workspace.directory("create").create
    workspace.directory("read").create
    workspace.file("read/foo.txt").create("foo")
    workspace.directory("update").create
    workspace.file("update/bar.txt").create{|f| f.body = "bar"}
    workspace.directory("delete").create
    workspace.file("delete/hoge.txt").create(:hoge)
    workspace.file("delete/fuga.txt").create(:fuga)

    class StoreAgent::Node::Object
      prepend Module.new {
        def test_sleep
          sleep 0.2
        end

        def create(*)
          super do
            test_sleep
            yield
          end
        end
        def read(*)
          super do
            test_sleep
            yield
          end
        end
        def update(*)
          super do
            test_sleep
            yield
          end
        end
        def delete(*)
          super do
            test_sleep
            yield
          end
        end
      }
    end
  end
  after :all do
    class StoreAgent::Node::Object
      prepend Module.new {
        def test_sleep
        end
      }
    end
  end

  context "オブジェクトcreate時のロック" do
    it "作成中のオブジェクトは排他ロックされている" do
      Process.fork do
        workspace.directory("create/dir").create
      end
      sleep 0.1
      response = true
      open(workspace.directory("create/dir").send(:lock_file_path)) do |f|
        response = f.flock File::LOCK_SH | File::LOCK_NB
      end
      Process.waitall
      expect(response).to be false
    end
    it "作成中のオブジェクトの親ディレクトリは排他ロックされている" do
      Process.fork do
        workspace.file("create/file.txt").create
      end
      sleep 0.1
      response = true
      open(workspace.directory("create").send(:lock_file_path)) do |f|
        response = f.flock File::LOCK_SH | File::LOCK_NB
      end
      Process.waitall
      expect(response).to be false
    end
  end

  context "オブジェクトread時のロック" do
    it "読み込み中のオブジェクトは共有ロックされている" do
      Process.fork do
        workspace.file("read/foo.txt").read
      end
      sleep 0.1
      response = true
      open(workspace.file("read/foo.txt").send(:lock_file_path)) do |f|
        response = f.flock File::LOCK_EX | File::LOCK_NB
      end
      Process.waitall
      expect(response).to be false
      expect(workspace.file("read/foo.txt").read).to eq "foo"
    end
    it "読み込み中のオブジェクトの親ディレクトリは共有ロックされている" do
      Process.fork do
        workspace.file("read/foo.txt").read
      end
      sleep 0.1
      response = true
      open(workspace.directory("read").send(:lock_file_path)) do |f|
        response = f.flock File::LOCK_EX | File::LOCK_NB
      end
      Process.waitall
      expect(response).to be false
    end
  end

  context "オブジェクトupdate時のロック" do
    it "更新中のオブジェクトは排他ロックされている" do
      Process.fork do
        workspace.file("update/bar.txt").update("test")
      end
      sleep 0.1
      response = true
      open(workspace.file("update/bar.txt").send(:lock_file_path)) do |f|
        response = f.flock File::LOCK_EX | File::LOCK_NB
      end
      Process.waitall
      expect(response).to be false
    end
    it "更新中のオブジェクトの親ディレクトリは排他ロックされている" do
      Process.fork do
        workspace.file("update/bar.txt").update("test")
      end
      sleep 0.1
      response = true
      open(workspace.directory("update").send(:lock_file_path)) do |f|
        response = f.flock File::LOCK_EX | File::LOCK_NB
      end
      Process.waitall
      expect(response).to be false
    end
  end

  context "オブジェクトdelete時のロック" do
    it "削除中のオブジェクトは排他ロックされている" do
      Process.fork do
        workspace.file("delete/hoge.txt").delete
      end
      sleep 0.1
      response = true
      open(workspace.file("delete/hoge.txt").send(:lock_file_path)) do |f|
        response = f.flock File::LOCK_EX | File::LOCK_NB
      end
      Process.waitall
      expect(response).to be false
    end
    it "削除中のオブジェクトの親ディレクトリは排他ロックされている" do
      Process.fork do
        workspace.file("delete/fuga.txt").delete
      end
      sleep 0.1
      response = true
      open(workspace.directory("delete").send(:lock_file_path)) do |f|
        response = f.flock File::LOCK_EX | File::LOCK_NB
      end
      Process.waitall
      expect(response).to be false
    end
  end
end
