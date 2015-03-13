require "store_agent/data_encoder/gzip_encoder"
require "store_agent/data_encoder/openssl_aes_256_cbc_encoder"

module StoreAgent
  # データを保存する際に使用するエンコーダ<br>
  # このクラス自体は継承して使用するためのインターフェースなので、そのままでは使用できない
  class DataEncoder
    def encode(*, &block)
      yield.force_encoding("UTF-8")
    end

    def decode(*, &block)
      yield.force_encoding("UTF-8")
    end
  end
end
