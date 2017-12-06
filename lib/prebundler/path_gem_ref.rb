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

      # @TODO: Individual gem calls can also specify a path, which
      # we don't currently handle. For now just use the gem's name
      # to complete the path.
      @path = File.join(options[:path], name)
    end

    def installable?
      false
    end

    def storable?
      false
    end

    def gemspecs
      @gemspecs ||= gemspec_files.map do |gemspec_file|
        Dir.chdir(File.dirname(gemspec_file)) do
          Bundler.load_gemspec(File.basename(gemspec_file))
        end
      end
    end

    alias_method :source, :path

    private

    def gemspec_files
      @gemspec_files ||= Dir[File.join(path, '*.gemspec')]
    end
  end
end
