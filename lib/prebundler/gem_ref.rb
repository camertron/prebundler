require 'rubygems/package'
require 'fileutils'
require 'set'

module Prebundler
  class GemRef
    REF_TYPES = [PathGemRef, GitGemRef]
    DEFAULT_SOURCE = 'https://rubygems.org'

    class << self
      def create(name, bundle_path, options = {})
        ref_type = REF_TYPES.find { |rt| rt.accepts?(options) } || self
        ref_type.new(name, bundle_path, options)
      end
    end

    attr_reader :name, :bundle_path, :groups
    attr_accessor :spec, :dependencies, :prefix

    def initialize(name, bundle_path, options = {})
      @name = name
      @bundle_path = bundle_path
      @groups = Set.new(options[:groups])
      @source = options[:source]
      @dependencies = options[:dependencies]
      @prefix = options[:prefix]
    end

    def to_gem
      "gem '#{name}', '= #{version}'"
    end

    def dependencies
      @dependencies ||= []
    end

    def source
      @source ||= DEFAULT_SOURCE
    end

    alias_method :remote, :source

    def id
      "#{name}-#{version}"
    end

    def version
      spec.version.to_s
    end

    def install
      # NOTE: the --platform argument doesn't work when --ignore-dependencies
      # is specified, no idea why
      Bundler.with_unbundled_env do
        system(
          { "GEM_HOME" => bundle_path },
          'gem install -N --ignore-dependencies '\
            "--source #{source} #{name} "\
            "--version #{version} "\
            "--platform #{Bundler.local_platform.to_s}"
        )
      end

      $?.exitstatus == 0
    end

    def install_from_tar(tar_file)
      puts 'Using ruby-based tar reader'
      File.open(tar_file) do |f|
        Gem::Package::TarReader.new(f) do |tar|
          tar.each do |entry|
            path = File.join(bundle_path, entry.full_name)

            if entry.directory?
              FileUtils.mkdir_p(path)
            else
              File.open(path, 'wb') do |new_file|
                new_file.write(entry.read)
              end
            end
          end
        end
      end

      true
    rescue => e
      return false
    end

    def add_to_tar(tar_file)
      tar_flags = File.exist?(tar_file) ? '-rf' : '-cf'

      system "tar -C #{bundle_path} #{tar_flags} #{tar_file} #{relative_gem_dir}"

      relative_gemspec_files.each do |relative_gemspec_file|
        system "tar -C #{bundle_path} -rf #{tar_file} #{relative_gemspec_file}"
      end

      if File.directory?(extension_dir)
        system "tar -C #{bundle_path} -rf #{tar_file} #{relative_extension_dir}"
      end

      gemspecs.each do |gemspec|
        gemspec.executables.each do |executable|
          system "tar -C #{bundle_path} -rf #{tar_file} #{File.join(relative_gem_dir, gemspec.bindir, executable)}"
        end
      end
    end

    def executables
      gemspecs.flat_map(&:executables)
    end

    def gemspecs
      @gemspecs ||= relative_gemspec_files.map do |relative_gemspec_file|
        Bundler.load_gemspec(File.join(bundle_path, relative_gemspec_file))
      end
    end

    def installable?
      true
    end

    def storable?
      true
    end

    def install_path
      File.join(bundle_path, 'gems')
    end

    def spec_path
      File.join(bundle_path, 'specifications')
    end

    def install_dir
      @install_dir ||= begin
        base = File.join(install_path, id)

        find_platform_dir(base) do |dir|
          File.directory?(dir)
        end
      end
    end

    def extension_dir
      File.join(bundle_path, relative_extension_dir)
    end

    def relative_extension_dir
      File.join('extensions', Bundler.local_platform.to_s, Gem.extension_api_version.to_s, id)
    end

    def relative_gem_dir
      @relative_gem_dir ||= begin
        base = File.join('gems', id)

        find_platform_dir(base) do |dir|
          File.directory?(File.join(bundle_path, dir))
        end
      end
    end

    def relative_gemspec_files
      Dir.chdir(bundle_path) do
        Dir.glob(File.join('specifications', "#{id}*.gemspec"))
      end
    end

    def tar_file
      file = File.join(Bundler.local_platform.to_s, Prebundler.platform_version, Gem.extension_api_version.to_s, "#{id}.tar")
      prefix && !prefix.empty? ? File.join(prefix, file) : file
    end

    private

    def find_platform_dir(base)
      platform = Bundler.local_platform.to_a

      platform.size.downto(0) do |i|
        dir = [base, *platform[0...i]].join('-')
        return dir if yield(dir)
      end

      base
    end
  end
end
