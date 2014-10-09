module StoreAgent
  class InvalidPathError < StandardError
  end

  class PermissionDeniedError < StandardError
    attr_reader :errors, :object, :permission

    def initialize(errors: nil, object: nil, permission: "")
      @errors = errors
      @object = object
      @permission = permission
    end

    def to_s
      if @errors
        "permission denied: user=#{@errors.first.object.user.identifier} " +
        @errors.map do |e|
          "permission=#{e.permission} object=#{e.object.path}"
        end.join(", ")
      else
        "permission denied: user=#{object.user.identifier} permission=#{permission} object=#{object.path}"
      end
    end
  end
end
