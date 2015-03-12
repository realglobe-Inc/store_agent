module StoreAgent
  module Validator
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

    def validates_to_be_excluded_slash!(value)
      if value.to_s.include?("/")
        raise ArgumentError, "#{value} includes '/'"
      end
    end

    def validates_to_be_not_superuser_identifier!(value)
      if value.to_s == StoreAgent.config.superuser_identifier
        raise ArgumentError, "#{value} is reserved for superuser"
      end
    end

    def validates_to_be_not_guest_identifier!(value)
      if value.to_s == StoreAgent.config.guest_identifier
        raise ArgumentError, "#{value} is reserved for guest"
      end
    end

    def validates_to_be_not_nil_value!(accessor_method_name)
      if send(accessor_method_name).nil?
        raise ArgumentError, "#{accessor_method_name} is nil"
      end
    end
  end
end
