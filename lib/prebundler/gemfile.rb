require 'tsort'

module Prebundler
  class Gemfile
    include TSort
    include Enumerable

    attr_reader :gems

    def initialize(gems)
      @gems = gems

      gems.each do |_, gem_ref|
        assign_groups(gem_ref, [])
      end
    end

    def each
      return to_enum(__method__) unless block_given?

      tsort_each do |name|
        yield name, gems[name]
      end
    end

    alias_method :each_pair, :each

    private

    # propagate groups to dependencies
    def assign_groups(gem_ref, seen)
      gem_ref.dependencies.each do |dep|
        next if seen.include?(dep)
        next unless gems[dep]
        gem_ref.groups.each { |group| gems[dep].groups << group }
        assign_groups(gems[dep], seen + [dep])
      end
    end

    def tsort_each_node(&block)
      gems.keys.each(&block)
    end

    def tsort_each_child(name, &block)
      gems[name].dependencies.each do |dep|
        yield dep if gems.include?(dep)
      end
    end
  end
end
