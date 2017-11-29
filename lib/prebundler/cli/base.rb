module Prebundler
  module Cli
    class Base
      class << self
        def run(out, global_options, options, args)
          new(out, global_options, options, args).run
        end
      end

      attr_reader :out, :global_options, :options, :args

      def initialize(out, global_options, options, args)
        @out = out
        @global_options = global_options
        @options = options
        @args = args
      end

      def run
        raise NotImplementedError, "please define '#{__method__}' in derived classes"
      end
    end
  end
end
