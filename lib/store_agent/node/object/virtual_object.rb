module StoreAgent
  module Node
    class VirtualObject < Object # :nodoc:
      def exists?
        false
      end
    end
  end
end
