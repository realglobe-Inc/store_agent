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
require "store_agent/data_encoder/encoder_shared_context"

RSpec.describe StoreAgent::DataEncoder::OpensslAes256CbcEncoder do
  before :all do
    StoreAgent.configure do |c|
      c.storage_data_encoders = [StoreAgent::DataEncoder::OpensslAes256CbcEncoder.new]
      c.attachment_data_encoders = [StoreAgent::DataEncoder::OpensslAes256CbcEncoder.new]
    end
  end
  let :workspace_name do
    "openssl_aes_256_cbc_encoder_test"
  end
  let :encoder do
    StoreAgent::DataEncoder::OpensslAes256CbcEncoder.new
  end

  include_context "encoder"

  it "データは openssl enc -e -aes-256-cbc ... でエンコードされた形式で保存される" do
    password = ENV["STORE_AGENT_DATA_ENCODER_PASSWORD"] || ""
    file = workspace.file("enc_data").create("encode のテスト")
    command = "openssl enc -d -aes-256-cbc -in #{file.storage_object_path} -k '#{password}'"
    expect(`#{command}`).to eq "encode のテスト"
  end
end
