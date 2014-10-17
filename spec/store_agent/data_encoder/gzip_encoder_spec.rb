require "spec_helper"
require "store_agent/data_encoder/encoder_shared_context"

RSpec.describe StoreAgent::DataEncoder::GzipEncoder do
  before :all do
    StoreAgent.configure do |c|
      c.storage_data_encoders = [StoreAgent::DataEncoder::GzipEncoder.new]
      c.attachment_data_encoders = [StoreAgent::DataEncoder::GzipEncoder.new]
    end
  end
  let :workspace_name do
    "gzip_encoder_test"
  end
  let :encoder do
    StoreAgent::DataEncoder::GzipEncoder.new
  end

  include_context "encoder"

  it "データは gzip ... でエンコードされた形式で保存される" do
    file = workspace.file("enc_data").create("encode のテスト")
    command = "gunzip -c #{file.storage_object_path}"
    expect(`#{command}`).to eq "encode のテスト"
  end
end
