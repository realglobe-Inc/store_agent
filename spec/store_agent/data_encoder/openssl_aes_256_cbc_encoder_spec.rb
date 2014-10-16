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
