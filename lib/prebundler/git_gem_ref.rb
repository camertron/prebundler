require 'fileutils'
require 'uri'
require 'digest/sha1'

module Prebundler
  class GitGemRef < GemRef
    class << self
      def accepts?(options)
        options.include?(:git) || options.include?(:github)
      end
    end

    attr_reader :strategy

    def initialize(name, bundle_path, options = {})
      super
      @strategy = options.include?(:git) ? :git : :github
    end

    def install
      FileUtils.mkdir_p(spec_path)
      FileUtils.mkdir_p(install_path)
      FileUtils.mkdir_p(cache_path)

      return if File.exist?(cache_dir) || File.exist?(install_dir)
      system "git clone #{uri} \"#{cache_dir}\" --bare --no-hardlinks --quiet"
      return $? if $?.exitstatus != 0
      system "git clone --no-checkout --quiet \"#{cache_dir}\" \"#{install_dir}\""
      return $? if $?.exitstatus != 0
      Dir.chdir(install_dir) { system "git reset --hard --quiet #{revision}" }
      serialize_gemspecs
      copy_gemspecs
      $?
    end

    def version
      revision[0...12]
    end

    def installable?
      true
    end

    def storable?
      false
    end

    def install_path
      File.join(bundle_path, 'bundler', 'gems')
    end

    def cache_path
      File.join(bundle_path, 'cache', 'bundler', 'git')
    end

    def cache_dir
      File.join(cache_path, "#{name}-#{uri_hash}")
    end

    def uri
      spec.source.uri
    end

    alias_method :source, :uri

    def revision
      spec.source.revision
    end

    def gemspecs
      @gemspecs ||= gemspec_files.map do |gemspec_file|
        Bundler.load_gemspec(gemspec_file)
      end
    end

    def install_dir
      File.join(install_path, "#{repo_name}-#{version}")
    end

    def repo_name
      @repo_name ||= URI.parse(uri).path.split('/').last.chomp('.git')
    end

    private

    def gemspec_files
      @gemspec_files ||= Dir[File.join(install_dir, '*.gemspec')]
    end

    def copy_gemspecs
      FileUtils.cp(gemspec_files, spec_path)
    end

    # adapted from
    # https://github.com/bundler/bundler/blob/fea23637886c1b1bde471c98344b8844f82e60ce/lib/bundler/source/git.rb#L237
    def serialize_gemspecs
      gemspec_files.each do |path|
        # Evaluate gemspecs and cache the result. Gemspecs
        # in git might require git or other dependencies.
        # The gemspecs we cache should already be evaluated.
        spec = Bundler.load_gemspec(path)
        next unless spec
        Bundler.rubygems.set_installed_by_version(spec)
        # Bundler.rubygems.validate(spec)
        File.open(path, 'wb') { |file| file.write(spec.to_ruby) }
      end
    end

    # copied from
    # https://github.com/bundler/bundler/blob/fea23637886c1b1bde471c98344b8844f82e60ce/lib/bundler/source/git.rb#L281
    def uri_hash
      if uri =~ %r{^\w+://(\w+@)?}
        # Downcase the domain component of the URI
        # and strip off a trailing slash, if one is present
        input = URI.parse(uri).normalize.to_s.sub(%r{/$}, "")
      else
        # If there is no URI scheme, assume it is an ssh/git URI
        input = uri
      end
      Bundler::SharedHelpers.digest(:SHA1).hexdigest(input)
    end
  end
end
