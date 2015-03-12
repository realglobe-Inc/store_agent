module StoreAgent
  class User
    include StoreAgent::Validator

    attr_reader :identifiers

    def initialize(*identifiers)
      @identifiers = identifiers.compact
      if @identifiers.empty?
        raise ArgumentError, "identifier(s) is required"
      end
      @identifiers = @identifiers.map do |identifier|
        if identifier.is_a?(Array)
          case identifier.length
          when 0
            raise ArgumentError, "identifier(s) contains empty array"
          when 1
            stringify_identifier(identifier.first)
          else
            identifier.map{|id| stringify_identifier(id)}
          end
        else
          stringify_identifier(identifier)
        end
      end
    end

    def identifier_array
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
  end

  class Superuser < User
    def initialize(*)
      @identifiers = [StoreAgent.config.superuser_identifier]
    end

    def super_user?
      true
    end
  end

  class Guest < User
    def initialize(*)
      @identifiers = [StoreAgent.config.guest_identifier]
    end

    def guest?
      true
    end
  end
end
