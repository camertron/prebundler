require 'securerandom'
require 'tmpdir'
require 'parallel'
require 'bundler'

module Prebundler
  module Cli
    class Install < Base
      def run
        prepare
        install
        check
      end

      private

      def prepare
        gem_list.each do |_, gem_ref|
          next if backend_file_list.include?(gem_ref.tar_file)
          next unless member_of_installable_group?(gem_ref)
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
          gem_ref.install
          store_gem(gem_ref, dest_file) if gem_ref.storable?
        end
      end

      def store_gem(gem_ref, dest_file)
        out.puts "Storing #{gem_ref.id}"
        gem_ref.add_to_tar(dest_file)
        config.storage_backend.store_file(dest_file, gem_ref.tar_file)
      end

      def check
        system 'bundle check'

        if $?.exitstatus != 0
          out.puts 'Bundle not satisfied, falling back to `bundle install`'
          system 'bundle install'
        end
      end

      def gem_list
        @gem_list ||= Prebundler::GemfileInterpreter.interpret(gemfile_path, bundle_path)
      end

      def backend_file_list
        @backend_file_list ||= config.storage_backend.list_files
      end

      def gemfile_path
        options.fetch(:gemfile)
      end

      def bundle_path
        options.fetch(:'bundle-path')
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
          all_groups = gem_list.flat_map { |_, gem_ref| gem_ref.groups }.uniq
          with_groups = (options[:with] || '').split(',').map { |g| g.strip.to_sym }
          without_groups = (options[:without] || '').split(',').map { |g| g.strip.to_sym }

          groups = with_groups.empty? ? all_groups : with_groups
          groups - without_groups
        end
      end
    end
  end
end
