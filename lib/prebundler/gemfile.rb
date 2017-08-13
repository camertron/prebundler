require 'tsort'

module Prebundler
  class Gemfile
    include TSort
    include Enumerable

    def initialize(gems)
      @gems = gems
    end

    def each
      return to_enum(__method__) unless block_given?

      tsort_each do |name|
        yield name, @gems[name]
      end
    end

    alias_method :each_pair, :each

    private

    def tsort_each_node(&block)
      @gems.keys.each(&block)
    end

    def tsort_each_child(name, &block)
      @gems[name].dependencies.each do |dep|
        yield dep if @gems.include?(dep)
      end
    end
  end
end
