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

RSpec.shared_context "encoder" do
  after :all do
    StoreAgent.configure do |c|
      c.storage_data_encoders = []
      c.attachment_data_encoders = []
    end
  end
  let :user do
    StoreAgent::User.new("foo")
  end
  let :workspace do
    user.workspace(workspace_name)
  end
  before do
    if !workspace.exists?
      workspace.create
      workspace.directory("foo").create
      workspace.file("foo/bar.txt").create("テスト")
    end
  end

  context "encode/decode のテスト" do
    it "バイナリ文字列を encode してから decode すると、元の文字列に戻る" do
      100.times.each do
        string = OpenSSL::Random.random_bytes(256)
        string.force_encoding("UTF-8")
        encoded_string = encoder.encode(string)
        expect(encoder.decode(encoded_string)).to eq string
      end
    end
    it "日本語文字列を encode してから decode すると、元の文字列に戻る" do
      100.times.each do
        string = "日本語を含むUTF-8文字列"
        encoded_string = encoder.encode(string)
        expect(encoder.decode(encoded_string)).to eq string
      end
    end
  end
  context "作成されたファイルのテスト" do
    it "メタデータはエンコードされているので、JSON 形式ではない" do
      encoded_data = open(workspace.root.metadata.file_path).read
      expect do
        Oj.load(encoded_data)
      end.to raise_error
    end
    it "パーミッション情報はエンコードされているので、JSON 形式ではない" do
      encoded_data = open(workspace.directory("foo").permission.file_path).read
      expect do
        Oj.load(encoded_data)
      end.to raise_error
    end
    it "ファイルはエンコードされている" do
      encoded_data = open(workspace.file("foo/bar.txt").storage_object_path).read
      expect(encoded_data).to_not eq "テスト"
      expect(workspace.file("foo/bar.txt").read).to eq "テスト"
    end
  end
end
