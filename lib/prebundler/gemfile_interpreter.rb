require 'set'

module Prebundler
  class GemfileInterpreter
    def self.interpret(gemfile_path, bundle_path, options = {})
      Gemfile.new(new(gemfile_path, bundle_path, options).gems)
    end

    attr_reader :gems, :gemfile_path, :bundle_path, :prefix

    def initialize(gemfile_path, bundle_path, options)
      @gems = {}
      @current_groups = [:global]
      @gemfile_path = gemfile_path
      @bundle_path = bundle_path
      @prefix = options[:prefix]
      instance_eval(File.read(gemfile_path))

      lockfile = Bundler::LockfileParser.new(File.read("#{gemfile_path}.lock"))

      lockfile.specs.each do |spec|
        gems[spec.name] ||= GemRef.create(spec.name, bundle_path, options)
        gems[spec.name].spec = spec
        gems[spec.name].dependencies = spec.dependencies.map(&:name)
      end
    end

    def current_context
      {
        path: @current_path,
        groups: @current_groups,
        source: @current_source,
        prefix: prefix
      }
    end

    def gem(name, *args)
      options = args.find { |a| a.is_a?(Hash) } || {}
      gems[name] = GemRef.create(name, bundle_path, current_context.merge(options))
    end

    def path(dir)
      @current_path = File.join(File.dirname(gemfile_path), dir)
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
      @current_groups = [:global]
    end

    def gemspec
      # do nothing
    end
  end
end
