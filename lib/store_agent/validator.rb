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

module StoreAgent
  # バリデーションに使用するメソッドを定義したモジュール
  module Validator
    # 文字列またはシンボルでないとエラー
    def validates_to_be_string_or_symbol!(value)
      case
      when value.nil?, value == "", value == :""
        raise ArgumentError, "#{value} is empty string or symbol"
      when !value.is_a?(String) && !value.is_a?(Symbol)
        raise ArgumentError, "#{value} is not string or symbol"
      else
        true
      end
    end

    # 文字列中に '/' を含むとエラー
    def validates_to_be_excluded_slash!(value)
      if value.to_s.include?("/")
        raise ArgumentError, "#{value} includes '/'"
      end
    end

    # スーパーユーザーのIDと一致している場合エラー
    def validates_to_be_not_superuser_identifier!(value)
      if value.to_s == StoreAgent.config.superuser_identifier
        raise ArgumentError, "#{value} is reserved for superuser"
      end
    end

    # ゲストユーザーのIDと一致している場合エラー
    def validates_to_be_not_guest_identifier!(value)
      if value.to_s == StoreAgent.config.guest_identifier
        raise ArgumentError, "#{value} is reserved for guest"
      end
    end

    # アクセサが nil を返す場合エラー
    def validates_to_be_not_nil_value!(accessor_method_name)
      if send(accessor_method_name).nil?
        raise ArgumentError, "#{accessor_method_name} is nil"
      end
    end
  end
end
