require "zlib"

module StoreAgent
  class DataEncoder
    # データをgzip圧縮して保存するためのエンコーダ<br>
    # 使用する際には StoreAgent.configure で初期化時に指定する
    #   StoreAgent.configure do |c|
    #     c.storage_data_encoders = [StoreAgent::DataEncoder::GzipEncoder.new]
    #   end
    class GzipEncoder < DataEncoder
      def encode(data, **_)
        super do
          StringIO.open("", "r+") do |sio|
            Zlib::GzipWriter.wrap(sio) do |gz|
              gz.write(data)
              gz.finish
            end
            sio.rewind
            sio.read
          end
        end
      end

      def decode(encrypted_data, **_)
        super do
          sio = StringIO.new(encrypted_data, "r")
          Zlib::GzipReader.wrap(sio) do |gz|
            gz.read
          end
        end
      end
    end
  end
end
