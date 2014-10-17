require "zlib"

module StoreAgent
  class DataEncoder
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
