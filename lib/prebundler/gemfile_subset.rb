require 'set'

module Prebundler
  class GemfileSubset
    attr_reader :gemfile, :included_gems, :additional_gems, :raw

    def self.from(*args)
      new(GemfileInterpreter.interpret(*args))
    end

    def initialize(gemfile)
      @gemfile = gemfile
      @included_gems = Set.new
      @additional_gems = []
      @raw = []
    end

    def include(gem_name)
      @included_gems << gem_name
    end

    def add(gem_name, **params)
      additional_gems << [gem_name, params]
    end

    def add_raw(str, group: nil)
      raw << [str, group]
    end

    def to_gemfile(include_dev_deps: true)
      deps = aggregate_deps(include_dev_deps)
      groups = group_deps(deps)

      additional_gems.each do |gem_name, params|
        options = params.dup
        version = options.delete(:version)
        group = options.delete(:group)

        requirements = ["gem '#{gem_name}'"]
        requirements << "'#{version}'" if version
        requirements += options.map { |k, v| "#{k}: '#{v}'" }

        groups[group] << requirements.join(', ')
      end

      raw.each do |str, group|
        groups[group] << str
      end

      ''.tap do |result|
        groups.each_with_index do |(remote, _), idx|
          result << "\n" if idx > 0
          result << "source '#{remote}' do\n"
          result << groups[remote].map { |g| "  #{g}" }.join("\n")
          result << "\nend\n"
        end
      end
    end

    private

    def group_deps(deps)
      Hash.new { |h, k| h[k] = [] }.tap do |ret|
        deps.each do |dep|
          if spec = gemfile.gems[dep.name]
            ret[spec.remote || GemRef::DEFAULT_SOURCE] << spec.to_gem
          else
            req_str = dep.requirements_list.map { |r| "'#{r}'" }.join(', ')
            ret[GemRef::DEFAULT_SOURCE] << "gem '#{dep.name}', #{req_str}"
          end
        end
      end
    end

    def aggregate_deps(include_dev_deps)
      dep_names = Set.new.tap do |result|
        included_gems.each do |included_gem_name|
          gemfile.gems[included_gem_name].gemspecs.each do |gemspec|
            result.merge(gemspec.runtime_dependencies.map(&:name))
            result.merge(gemspec.development_dependencies.map(&:name)) if include_dev_deps
          end
        end
      end

      dep_names.map { |dep_name| gemfile.gems[dep_name] }.compact
    end
  end
end
