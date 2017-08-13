module Prebundler
  class PathGemRef < GemRef
    class << self
      def accepts?(options)
        !!options[:path]
      end
    end

    def initialize(name, options = {})
      super
      @path = options[:path]
    end

    def installable?
      false
    end

    def storable?
      false
    end
  end
end
