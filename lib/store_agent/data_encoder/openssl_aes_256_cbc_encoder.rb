module StoreAgent
  class DataEncoder
    # データを OpenSSL AES-256-CBC で暗号化して保存するためのエンコーダ
    #   StoreAgent.configure do |c|
    #     c.storage_data_encoders = [StoreAgent::DataEncoder::OpensslAes256CbcEncoder]
    #   end
    # 暗号化にパスワードを使用する場合、環境変数で指定する
    #   $ env STORE_AGENT_DATA_ENCODER_PASSWORD=password ruby-command
    # 指定が無い場合には空文字列をパスワードとして使用する
    class OpensslAes256CbcEncoder < DataEncoder
      def initialize # :nodoc:
        @password = ENV["STORE_AGENT_DATA_ENCODER_PASSWORD"] || ""
        @encryptor = OpenSSL::Cipher::AES.new(256, "CBC")
      end

      def encode(data, password: @password, **_)
        super do
          @encryptor.encrypt
          salt = OpenSSL::Random.random_bytes(8)
          encrypted_data = crypt(data: data, password: password, salt: salt)
          "Salted__#{salt}#{encrypted_data}"
        end
      end

      def decode(encrypted_data, password: @password, **_)
        super do
          @encryptor.decrypt
          encrypted_data.force_encoding("ASCII-8BIT")
          salt = encrypted_data[8..15]
          data = encrypted_data[16..-1]
          crypt(data: data, password: password, salt: salt)
        end
      end

      private

      def crypt(data: "", password: "", salt: "")
        md5_base = "#{password}#{salt}".force_encoding("ASCII-8BIT")
        md5_digest1 = OpenSSL::Digest::MD5.new(md5_base).digest
        md5_digest2 = OpenSSL::Digest::MD5.new("#{md5_digest1}#{md5_base}").digest
        md5_digest3 = OpenSSL::Digest::MD5.new("#{md5_digest2}#{md5_base}").digest
        @encryptor.padding = 1
        @encryptor.key = "#{md5_digest1}#{md5_digest2}"
        @encryptor.iv = md5_digest3
        @encryptor.update(data) + @encryptor.final
      end
    end
  end
end
