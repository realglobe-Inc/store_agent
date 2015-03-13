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
