require 'shellwords'

module Prebundler
  class Configurator
    attr_accessor :storage_backend, :gem_sources

    def initialize
      @gem_sources = []
    end
  end
end
