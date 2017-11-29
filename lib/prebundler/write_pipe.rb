module Prebundler
  class WritePipe
    def initialize
      @silent = false
    end

    def write(text)
      return if silent?
      STDOUT.write(text)
    end

    def puts(text)
      return if silent?
      STDOUT.write("#{text}\n")
    end

    def silence!
      @silent = true
      self
    end

    def silent?
      !!@silent
    end
  end
end
