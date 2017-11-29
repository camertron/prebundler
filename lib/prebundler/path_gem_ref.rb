module Prebundler
  class PathGemRef < GemRef
    class << self
      def accepts?(options)
        !!options[:path]
      end
    end

    attr_reader :path

    def initialize(name, bundle_path, options = {})
      super
      @path = options[:path]
    end

    def installable?
      false
    end

    def storable?
      false
    end

    alias_method :source, :path
  end
end
