module StoreAgent
  class InvalidPathError < StandardError
  end

  class InvalidNodeTypeError < StandardError
    attr_reader :src_object, :dest_object

    def initialize(src_object: nil, dest_object: nil)
      @src_object = src_object
      @dest_object = dest_object
    end

    def to_s
      if @src_object && @dest_object
        "invalid node type: '#{@src_object.path}' is #{@src_object.filetype}, '#{@dest_object.path}' is #{@dest_object.filetype}"
      else
        "invalid node type"
      end
    end
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
        "permission denied: user=#{@errors.first.object.current_user.identifiers} " +
        @errors.map do |e|
          "workspace=#{e.object.workspace.namespace} permission=#{e.permission} object=#{e.object.path}"
        end.join(", ")
      else
        "permission denied: user=#{object.current_user.identifiers} workspace=#{object.workspace.namespace} permission=#{permission} object=#{object.path}"
      end
    end
  end

  class InvalidRevisionError < StandardError
    attr_reader :path, :revision

    def initialize(path: "", revision: "")
      @path = path
      @revision = revision
    end

    def to_s
      "invalid revision: path=#{path} revision=#{revision}"
    end
  end
end
