module StoreAgent
  class DataEncoder
    class OpensslAes256CbcEncoder < DataEncoder
      def initialize
        @default_password = ENV["STORE_AGENT_DATA_ENCODER_PASSWORD"] || ""
        @encryptor = OpenSSL::Cipher::AES.new(256, "CBC")
      end

      def encode(data, password: @default_password, **_)
        super do
          @encryptor.encrypt
          salt = OpenSSL::Random.random_bytes(8)
          encrypted_data = crypt(data: data, password: password, salt: salt)
          "Salted__#{salt}#{encrypted_data}"
        end
      end

      def decode(encrypted_data, password: @default_password, **_)
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
