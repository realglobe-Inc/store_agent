module StoreAgent
  class User
    attr_reader :identifiers

    def initialize(*identifiers)
      @identifiers = identifiers.flatten.compact
      if @identifiers.empty?
        raise ArgumentError, "identifier(s) is required"
      end
      @identifiers.each do |identifier|
        StoreAgent::Validator.validates_to_be_string_or_symbol!(identifier)
        StoreAgent::Validator.validates_to_be_excluded_slash!(identifier)
        StoreAgent::Validator.validates_to_be_not_superuser_identifier!(identifier)
        StoreAgent::Validator.validates_to_be_not_guest_identifier!(identifier)
      end
    end

    def identifier
      identifiers.last
    end

    def super_user?
      false
    end

    def guest?
      false
    end

    def workspace(namespace)
      StoreAgent::Workspace.new(user: self, namespace: namespace)
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
