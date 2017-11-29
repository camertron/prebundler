module Prebundler
  autoload :Cli,                'prebundler/cli'
  autoload :Configurator,       'prebundler/configurator'
  autoload :FileBackend,        'prebundler/file_backend'
  autoload :PathGemRef,         'prebundler/path_gem_ref'
  autoload :Gemfile,            'prebundler/gemfile'
  autoload :GemfileInterpreter, 'prebundler/gemfile_interpreter'
  autoload :GemRef,             'prebundler/gem_ref'
  autoload :GitGemRef,          'prebundler/git_gem_ref'
  autoload :S3Backend,          'prebundler/s3_backend'
  autoload :WritePipe,          'prebundler/write_pipe'

  class << self
    attr_reader :config

    def configure
      return if configured?
      @config = Configurator.new
      yield @config
    end

    def configured?
      !!@config
    end
  end
end
