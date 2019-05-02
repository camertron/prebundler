# frozen_string_literal: true

require 'aws-sdk'

module Prebundler
  class S3Backend
    attr_reader :access_key_id, :secret_access_key, :bucket, :region

    def initialize(options = {})
      @bucket             = options.fetch(:bucket)

      @client             = options.fetch(:client, nil)
      @access_key_id      = options.fetch(:access_key_id, nil)
      @secret_access_key  = options.fetch(:secret_access_key, nil)
      @region             = options.fetch(:region) { ENV['AWS_REGION'] || 'us-east-1' }
    end

    def store_file(source_file, dest_file)
      File.open(source_file) do |io|
        client.put_object(bucket: bucket, key: dest_file, body: io)
      end
    end

    def retrieve_file(source_file, dest_file)
      client.get_object(
        bucket: bucket,
        key: source_file,
        response_target: dest_file
      )
    end

    def list_files
      truncated = true
      continuation_token = nil
      files = []
      base_options = {
        bucket: bucket,
        prefix: "#{Bundler.local_platform}/#{Prebundler.platform_version}/#{Gem.extension_api_version}"
      }

      while truncated
        options = if continuation_token
          base_options.merge(continuation_token: continuation_token)
        else
          base_options
        end

        response = client.list_objects_v2(options)
        truncated = response.is_truncated
        continuation_token = response.next_continuation_token

        response.contents.each do |file|
          files << file.key
        end
      end

      files
    end

    def docker_flags
      []
    end

    private

    def client
      @client ||= Aws::S3::Client.new(region: region, credentials: credentials)
    end

    def credentials
      @credentials ||= Aws::Credentials.new(access_key_id, secret_access_key)
    end
  end
end
