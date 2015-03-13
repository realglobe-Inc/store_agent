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
  # オブジェクトの操作を行うユーザー
  class User
    include StoreAgent::Validator

    attr_reader :identifiers

    # ユーザーの初期化は以下のようにして行う
    #   StoreAgent::User.new("foo")
    #   StoreAgent::User.new("foo", "bar")
    #   StoreAgent::User.new(["foo", "bar", "baz"])
    #   StoreAgent::User.new("foo", ["bar", "hoge"], "fuga")
    def initialize(*identifiers)
      identifiers.compact!
      if identifiers.empty?
        raise ArgumentError, "identifier(s) is required"
      end
      @identifiers = identifiers.map do |identifier|
        if identifier.is_a?(Array)
          stringify_map_identifier(identifier)
        else
          stringify_identifier(identifier)
        end
      end
    end

    def identifier_array # :nodoc:
      [identifiers.last].flatten
    end

    def identifier
      identifier_array.first
    end

    def super_user?
      false
    end

    def guest?
      false
    end

    # 操作対象のワークスペースを指定する
    def workspace(namespace)
      StoreAgent::Workspace.new(current_user: self, namespace: namespace)
    end

    private

    def stringify_identifier(identifier)
      validates_to_be_string_or_symbol!(identifier)
      validates_to_be_excluded_slash!(identifier)
      validates_to_be_not_superuser_identifier!(identifier)
      validates_to_be_not_guest_identifier!(identifier)
      identifier.to_s
    end

    def stringify_map_identifier(identifiers_array)
      case identifiers_array.length
      when 0
        raise ArgumentError, "identifier(s) contains empty array"
      when 1
        stringify_identifier(identifiers_array.first)
      else
        identifiers_array.map{|id| stringify_identifier(id)}
      end
    end
  end

  # スーパーユーザーは全オブジェクトに対して全権限を持つ
  #   super_user = StoreAgent::Superuser.new
  #   super_user.workspace("ws").file("file.txt").create
  class Superuser < User
    def initialize(*)
      @identifiers = [StoreAgent.config.superuser_identifier]
    end

    def super_user? # :nodoc:
      true
    end
  end

  # ゲストユーザーはデフォルトの設定では何の権限も持たない
  #   guest = StoreAgent::Guest.new
  #   guest.workspace("ws").file("file.txt").read
  class Guest < User
    def initialize(*)
      @identifiers = [StoreAgent.config.guest_identifier]
    end

    def guest? # :nodoc:
      true
    end
  end
end
