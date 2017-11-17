require 'securerandom'
require 'tmpdir'
require 'parallel'
require 'bundler'
require 'digest/sha2'
require 'etc'

module Prebundler
  module CLI
    class Install
      class << self
        def run(args)
          new.run
        end
      end

      def run
        prepare
        install
        check
      end

      private

      def prepare
        gem_list.each do |_, gem_ref|
          next if backend_file_list.include?(gem_ref.tar_file)
          install_gem(gem_ref) if gem_ref.installable?
        end
      end

      def install
        Parallel.each(gem_list, in_processes: Etc.nprocessors) do |_, gem_ref|
          next unless gem_ref.installable?

          unless File.exist?(gem_ref.install_dir)
            install_gem(gem_ref)
          end

          puts "Installed #{gem_ref.id}"
        end
      end

      def install_gem(gem_ref)
        dest_file = File.join(Dir.tmpdir, "#{SecureRandom.hex}.tar")

        if backend_file_list.include?(gem_ref.tar_file)
          config.storage_backend.retrieve_file(gem_ref.tar_file, dest_file)
          gem_ref.install_from_tar(dest_file)
          FileUtils.rm(dest_file)
        else
          puts "Installing #{gem_ref.id} from source"
          gem_ref.install
          store_gem(gem_ref, dest_file) if gem_ref.storable?
        end
      end

      def store_gem(gem_ref, dest_file)
        puts "Storing #{gem_ref.id}"
        gem_ref.add_to_tar(dest_file)
        config.storage_backend.store_file(dest_file, gem_ref.tar_file)
      end

      def check
        system 'bundle check'

        if $?.exitstatus != 0
          puts 'Bundle not satisfied, falling back to `bundle install`'
          system 'bundle install'
        end
      end

      def archive_file
        "archive_#{gem_digest}.tar"
      end

      def archive_path
        "/tmp/#{archive_file}"
      end

      def gem_digest
        @gem_digest ||= begin
          digest = Digest::SHA2.new
          gem_list.each { |_, gem_ref| digest << gem_ref.id }
          digest.hexdigest
        end
      end

      def gem_list
        @gem_list ||= Prebundler::GemfileInterpreter.interpret(gemfile_path)
      end

      def backend_file_list
        @backend_file_list ||= config.storage_backend.list_files
      end

      def gemfile_path
        ENV.fetch('BUNDLE_GEMFILE', 'Gemfile')
      end

      def bundle_path
        ENV.fetch('BUNDLE_PATH', Bundler.bundle_path.to_s)
      end

      def config
        Prebundler.config
      end
    end
  end
end
