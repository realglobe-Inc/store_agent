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

RSpec.describe StoreAgent::DataEncoder do
  before :all do
    StoreAgent.configure do |c|
      c.storage_data_encoders = [] <<
        StoreAgent::DataEncoder::GzipEncoder.new <<
        StoreAgent::DataEncoder::OpensslAes256CbcEncoder.new
      c.attachment_data_encoders = [] <<
        StoreAgent::DataEncoder::GzipEncoder.new <<
        StoreAgent::DataEncoder::OpensslAes256CbcEncoder.new
    end
  end
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
    user.workspace("gzip_and_openssl_encoder_test")
  end
  let :password do
    ENV["STORE_AGENT_DATA_ENCODER_PASSWORD"] || ""
  end
  before do
    if !workspace.exists?
      workspace.create
      workspace.directory("foo").create
      workspace.file("foo/bar.txt").create("encode のテスト")
    end
  end

  it "データは gzip -c ... | openssl ... でエンコードされた形式で保存される" do
    file = workspace.file("foo/bar.txt")
    command = "openssl enc -d -aes-256-cbc -in #{file.storage_object_path} -k '#{password}' | gunzip"
    expect(`#{command}`).to eq "encode のテスト"
  end
  it "メタデータは gzip -c ... | openssl ... でエンコードされた形式で保存される" do
    dir = workspace.directory("foo")
    command = "openssl enc -d -aes-256-cbc -in #{dir.metadata.file_path} -k '#{password}' | gunzip"
    expect do
      Oj.load(`#{command}`)
    end.to_not raise_error
  end
  it "メタデータのファイルサイズはエンコード前のサイズ" do
    dir = workspace.directory("bitesize_test").create
    file = workspace.file("bitesize_test/hoge.txt").create("12 byte file")
    expect(file.metadata["bytes"]).to eq 12
    expect(workspace.directory("bitesize_test").metadata.disk_usage).to eq 4108
  end
  it "パーミッション情報は gzip -c ... | openssl ... でエンコードされた形式で保存される" do
    file = workspace.file("foo/bar.txt")
    command = "openssl enc -d -aes-256-cbc -in #{file.permission.file_path} -k '#{password}' | gunzip"
    expect do
      Oj.load(`#{command}`)
    end.to_not raise_error
  end
end
