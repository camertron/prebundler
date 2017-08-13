require 'fileutils'

module Prebundler
  class FileBackend
    attr_reader :local_path, :docker_mount_point

    def initialize(options = {})
      @local_path = options.fetch(:local_path)
      @docker_mount_point = options.fetch(:docker_mount_point)
    end

    def store_file(source_file, dest_file)
      FileUtils.cp(source_file, File.join(docker_mount_point, dest_file))
    end

    def retrieve_file(source_file, dest_file)
      FileUtils.cp(File.join(local_path, source_file), dest_file)
    end

    def list_files
      Dir.chdir(docker_mount_point) { Dir.glob('**/*.*') }
    end

    def docker_flags
      ['-v', "#{File.expand_path(local_path)}:#{docker_mount_point}"]
    end
  end
end
