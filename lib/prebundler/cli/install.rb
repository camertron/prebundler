require 'securerandom'
require 'tmpdir'
require 'parallel'
require 'fileutils'
require 'yaml'

module Prebundler
  module Cli
    class BundleFailedError < StandardError
      attr_reader :exitstatus

      def initialize(message, exitstatus)
        super(message)
        @exitstatus = exitstatus
      end
    end

    class Install < Base
      def run
        prepare
        install
        update_bundle_config
        generate_binstubs
        # always run `bundle install` just in case
        bundle_install
      rescue BundleFailedError => e
        out.puts e.message
        exit e.exitstatus
      end

      private

      def prepare
        FileUtils.mkdir_p(bundle_path)
        ENV['BUNDLE_GEMFILE'] = gemfile_path

        gem_list.each do |name, gem_ref|
          next if backend_file_list.include?(gem_ref.tar_file)
          next unless member_of_installable_group?(gem_ref)

          # Edge case: installation could fail if dependencies of this
          # gem ref haven't been installed yet. They should have been
          # prepared by this point because of the tsort logic in the
          # gemfile class, but we need to actually install them in
          # order to install this current gem. A good example is nokogiri,
          # which can't build its native extension without mini-portile2.
          gem_ref.dependencies.each do |dep|
            if gem_list.gems[dep]
              install_gem_ref(gem_list.gems[dep])
            else
              out.puts "Oops, couldn't find dependency #{dep}"
            end
          end

          install_gem(gem_ref) if gem_ref.installable?
        end
      end

      def install
        if options[:jobs] <= 1
          install_in_serial
        else
          install_in_parallel
        end
      end

      def install_in_serial
        gem_list.each do |_, gem_ref|
          install_gem_ref(gem_ref)
        end
      end

      def install_in_parallel
        Parallel.each(gem_list, in_processes: options[:jobs]) do |_, gem_ref|
          install_gem_ref(gem_ref)
        end
      end

      def install_gem_ref(gem_ref)
        return unless gem_ref.installable?

        unless member_of_installable_group?(gem_ref)
          out.puts "Skipping #{gem_ref.id} because of its group"
          return
        end

        if File.exist?(gem_ref.install_dir)
          out.puts "Skipping #{gem_ref.id} because it's already installed"
        else
          install_gem(gem_ref)
          out.puts "Installed #{gem_ref.id}"
        end
      end

      def install_gem(gem_ref)
        dest_file = File.join(Dir.tmpdir, "#{SecureRandom.hex}.tar")

        if backend_file_list.include?(gem_ref.tar_file)
          out.puts "Installing #{gem_ref.id} from backend"
          config.storage_backend.retrieve_file(gem_ref.tar_file, dest_file)
          gem_ref.install_from_tar(dest_file)
          FileUtils.rm(dest_file)
        else
          out.puts "Installing #{gem_ref.id} from source"

          if gem_ref.install
            store_gem(gem_ref, dest_file) if gem_ref.storable?
          else
            out.puts "Failed to install #{gem_ref.id} from source"
          end
        end
      end

      def store_gem(gem_ref, dest_file)
        out.puts "Storing #{gem_ref.id}"
        gem_ref.add_to_tar(dest_file)
        config.storage_backend.store_file(dest_file, gem_ref.tar_file)
      end

      def update_bundle_config
        file = Bundler.app_config_path.join('config').to_s
        config = File.exist?(file) ? YAML.load_file(file) : {}
        config['BUNDLE_WITH'] = with_groups.join(':') unless with_groups.empty?
        config['BUNDLE_WITHOUT'] = without_groups.join(':') unless without_groups.empty?
        FileUtils.mkdir_p(File.dirname(file))
        File.write(file, YAML.dump(config))
      end

      def generate_binstubs
        return unless options[:binstubs]
        out.puts 'Generating binstubs...'

        gems_with_executables = gem_list.gems.values.select do |gem_ref|
          next false unless member_of_installable_group?(gem_ref)
          !gem_ref.executables.empty?
        end

        return if gems_with_executables.empty?

        system "bundle binstubs #{gems_with_executables.map(&:name).join(' ')}"
        system "bundle binstubs --force bundler"
        out.puts 'Done generating binstubs'
      end

      def bundle_install
        system "bundle install #{bundle_install_args}"

        if $?.exitstatus != 0
          raise BundleFailedError.new(
            "bundler exited with status code #{$?.exitstatus}", $?.exitstatus
          )
        end

        system "bundle check --gemfile #{gemfile_path}"

        if $?.exitstatus != 0
          raise BundleFailedError.new('bundle could not be satisfied', $?.exitstatus)
        end
      end

      def bundle_install_args
        [].tap do |args|
          args << "--gemfile #{gemfile_path}"
          args << "--with #{with_groups.join(',')}" unless with_groups.empty?
          args << "--without #{without_groups.join(',')}" unless without_groups.empty?
          args << "--jobs #{options[:jobs]}"
          args << "--binstubs" if options[:binstubs]
        end.join(' ')
      end

      def gem_list
        @gem_list ||= Prebundler::GemfileInterpreter.interpret(
          gemfile_path, bundle_path, prefix: options[:prefix]
        )
      end

      def backend_file_list
        @backend_file_list ||= config.storage_backend.list_files
      end

      def gemfile_path
        options.fetch(:gemfile)
      end

      def bundle_path
        File.expand_path(options.fetch(:'bundle-path'))
      end

      def config
        Prebundler.config
      end

      def member_of_installable_group?(gem_ref)
        return true if gem_ref.groups.empty?
        gem_ref.groups.any? { |g| groups.include?(g) }
      end

      def groups
        @groups ||= begin
          all_groups = gem_list.flat_map { |_, gem_ref| gem_ref.groups.to_a }.uniq
          (all_groups + with_groups).uniq - without_groups
        end
      end

      def with_groups
        @with_groups ||= (options[:with] || '').split(/[:, ]/).map { |g| g.strip.to_sym }
      end

      def without_groups
        @without_groups ||= (options[:without] || '').split(/[:, ]/).map { |g| g.strip.to_sym }
      end
    end
  end
end
