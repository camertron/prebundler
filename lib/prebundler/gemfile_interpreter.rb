module Prebundler
  class GemfileInterpreter
    def self.interpret(path, bundle_path)
      Gemfile.new(new(path, bundle_path).gems)
    end

    attr_reader :gems, :bundle_path

    def initialize(path, bundle_path)
      @gems = {}
      @current_groups = []
      @bundle_path = bundle_path
      instance_eval(File.read(path))

      lockfile = Bundler::LockfileParser.new(File.read("#{path}.lock"))

      lockfile.specs.each do |spec|
        gems[spec.name] ||= GemRef.create(spec.name, bundle_path)
        gems[spec.name].spec = spec
        gems[spec.name].dependencies = spec.dependencies.map(&:name)
      end
    end

    def current_context
      {
        path: @current_path,
        groups: @current_groups,
        source: @current_source
      }
    end

    def gem(name, *args)
      options = args.find { |a| a.is_a?(Hash) } || {}
      gems[name] = GemRef.create(name, bundle_path, current_context.merge(options))
    end

    def path(dir)
      @current_path = dir
      yield if block_given?
      @current_path = nil
    end

    def source(url)
      @current_source = url
      yield if block_given?
      @current_source = nil
    end

    def group(*groups)
      @current_groups = groups
      yield if block_given?
      @current_groups = []
    end

    def gemspec
      # do nothing
    end
  end
end
