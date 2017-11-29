require 'fileutils'

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

    attr_reader :name, :bundle_path
    attr_accessor :spec, :dependencies

    def initialize(name, bundle_path, options = {})
      @name = name
      @bundle_path = bundle_path
      @groups = options[:groups]
      @source = options[:source]
      @dependencies = options[:dependencies]
    end

    def dependencies
      @dependencies ||= []
    end

    def groups
      @groups ||= []
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
      system "gem install -N -i #{bundle_path} --ignore-dependencies --source #{source} #{name} -v #{version}"
      $?.exitstatus == 0
    end

    def install_from_tar(tar_file)
      system "tar -C #{bundle_path} -xf #{tar_file}"
      $?.exitstatus == 0
    end

    def add_to_tar(tar_file)
      tar_flags = File.exist?(tar_file) ? '-rf' : '-cf'

      system "tar -C #{bundle_path} #{tar_flags} #{tar_file} #{relative_gem_dir}"
      system "tar -C #{bundle_path} -rf #{tar_file} #{relative_gemspec_dir}"

      if File.directory?(extension_dir)
        system "tar -C #{bundle_path} -rf #{tar_file} #{relative_extension_dir}"
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

    def relative_gemspec_dir
      File.join('specifications', gemspec_file)
    end

    def tar_file
      File.join(Bundler.local_platform.to_s, Gem.extension_api_version.to_s, "#{id}.tar")
    end

    def gemspec_file
      "#{id}.gemspec"
    end
  end
end
