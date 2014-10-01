module StoreAgent
  module Validator
    module_function

    def validates_to_be_string_or_symbol!(value)
      case
      when value.nil?, value == "", value == :""
        raise ArgumentError, "#{value} is empty string or symbol"
      when !value.is_a?(String) && !value.is_a?(Symbol)
        raise ArgumentError, "#{value} is not string or symbol"
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

    def validates_to_be_present_object!(object)
      if !object.exists?
        raise "object not found: #{object.path}"
      end
    end

    def validates_to_be_absent_object!(object)
      if object.exists?
        raise "object already exists: #{object.path}"
      end
    end
  end
end
