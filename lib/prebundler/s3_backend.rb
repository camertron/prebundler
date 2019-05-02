# frozen_string_literal: true

require 'aws-sdk'
require 'securerandom'

module Prebundler
  class S3Backend
    attr_reader :access_key_id, :secret_access_key, :role_arn, :profile
    attr_reader :bucket, :region, :endpoint, :force_path_style

    def initialize(options = {})
      @bucket             = options.fetch(:bucket)

      @access_key_id      = options.fetch(:access_key_id, nil)
      @secret_access_key  = options.fetch(:secret_access_key, nil)
      @role_arn           = options.fetch(:role_arn, nil)
      @profile            = options.fetch(:profile, nil)
      @region             = options.fetch(:region) { ENV['AWS_REGION'] || 'us-east-1' }
      @endpoint           = options.fetch(:endpoint, nil)
      @force_path_style   = options.fetch(:force_path_style, false)
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
      @client ||= Aws::S3::Client.new({}.tap do |o|
        o[:credentials]       = credentials
        o[:region]            = region
        o[:endpoint]          = endpoint if endpoint
        o[:force_path_style]  = true if force_path_style
      end)
    end

    def credentials
      @credentials ||= begin
        if role_arn
          Aws::AssumeRoleCredentials.new({}.tap do |o|
            o[:role_arn]           = role_arn
            o[:role_session_name]  = "prebundler-#{SecureRandom.hex}"
            if access_key_id && secret_access_key
              o[:client] = Aws::STS::Client.new(
                region: region,
                credentials: Aws::Credentials.new(access_key_id, secret_access_key)
              )
            end
          end)
        elsif access_key_id && secret_access_key
          Aws::Credentials.new(access_key_id, secret_access_key)
        else
          Aws::SharedCredentials.new(profile_name: profile)
        end
      end
    end
  end
end
