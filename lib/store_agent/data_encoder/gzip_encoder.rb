require "zlib"

module StoreAgent
  module DataEncoder
    class GzipEncoder
      def encode(data, **_)
        StringIO.open("", "r+") do |sio|
          Zlib::GzipWriter.wrap(sio) do |gz|
            gz.write(data)
            gz.finish
          end
          sio.rewind
          sio.read
        end
      end

      def decode(encrypted_data, **_)
        sio = StringIO.new(encrypted_data, "r")
        Zlib::GzipReader.wrap(sio) do |gz|
          gz.read
        end
      end
    end
  end
end
