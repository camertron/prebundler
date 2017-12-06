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
    attr_accessor :spec, :dependencies

    def initialize(name, bundle_path, options = {})
      @name = name
      @bundle_path = bundle_path
      @groups = Set.new(options[:groups])
      @source = options[:source]
      @dependencies = options[:dependencies]
    end

    def dependencies
      @dependencies ||= []
    end

    def source
      @source ||= DEFAULT_SOURCE
    end

    def id
      "#{name}-#{version}"
    end

    def version
      spec.version.to_s
    end

    def install
      system({ "GEM_HOME" => bundle_path }, "gem install -N --ignore-dependencies --source #{source} #{name} -v #{version}")
      $?.exitstatus
    end

    def install_from_tar(tar_file)
      system "tar -C #{bundle_path} -xf #{tar_file}"
      $?.exitstatus == 0
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

      executables.each do |executable|
        system "tar -C #{bundle_path} -rf #{tar_file} #{File.join('bin', executable)}"
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
      File.join(install_path, id)
    end

    def extension_dir
      File.join(bundle_path, relative_extension_dir)
    end

    def relative_extension_dir
      File.join('extensions', Bundler.local_platform.to_s, Gem.extension_api_version.to_s, id)
    end

    def relative_gem_dir
      File.join('gems', id)
    end

    def relative_gemspec_files
      [File.join('specifications', gemspec_file)]
    end

    def tar_file
      File.join(Bundler.local_platform.to_s, Gem.extension_api_version.to_s, "#{id}.tar")
    end

    def gemspec_file
      "#{id}.gemspec"
    end
  end
end
