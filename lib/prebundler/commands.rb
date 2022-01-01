require 'gli'
require 'etc'
require 'bundler'
require 'prebundler'
require 'prebundler/version'

module Prebundler
  class Commands
    extend GLI::App

    program_desc 'Gem dependency prebuilder'

    version Prebundler::VERSION

    subcommand_option_handling :normal
    arguments :strict

    def self.out
      @out ||= Prebundler::WritePipe.new
    end

    desc "Don't log to stdout"
    switch [:s, :silent]

    desc 'Path to config file.'
    default_value './.prebundle_config'
    flag [:c, :config]

    desc 'Install gems from the Gemfile.lock.'
    command :install do |c|
      c.desc 'Maximum number of parallel gem installs.'
      c.default_value Etc.nprocessors
      c.flag [:j, :jobs], type: Integer

      c.desc 'Path to the gemfile to install gems from.'
      c.default_value ENV.fetch('BUNDLE_GEMFILE', './Gemfile')
      c.flag [:g, :gemfile]

      c.desc 'Path to the bundle installation directory.'
      c.default_value ENV.fetch('BUNDLE_PATH', Bundler.bundle_path.to_s)
      c.flag [:b, :'bundle-path']

      c.desc 'Backend prefix (i.e. path) at which to store gems.'
      c.flag [:prefix]

      c.desc 'A comma-separated list of groups referencing gems to install.'
      c.flag :with

      c.desc 'A comma-separated list of groups referencing gems to skip during installation.'
      c.flag :without

      c.desc 'Generate binstubs for installed gems.'
      c.default_value true
      c.switch :binstubs

      c.desc 'Retry failed network requests n times (currently not implemented).'
      c.default_value 1
      c.flag [:retry], type: Integer

      c.action do |global_options, options, args|
        raise 'Must specify a non-zero number of jobs' if options[:jobs] < 1
        Prebundler::Cli::Install.run(out, global_options, options, args)
      end
    end

    desc 'List each gem and associated source.'
    command :list do |c|
      c.desc 'Path to the gemfile.'
      c.default_value ENV.fetch('BUNDLE_GEMFILE', './Gemfile')
      c.flag [:g, :gemfile]

      c.desc 'Filter by source. Will perform partial matching.'
      c.flag [:s, :source], multiple: true

      c.action do |global_options, options, args|
        Prebundler::Cli::List.run(out, global_options, options, args)
      end
    end

    desc 'Generate a subset of a Gemfile.'
    command :subset do |c|
      c.desc 'Path to the gemfile.'
      c.default_value ENV.fetch('BUNDLE_GEMFILE', './Gemfile')
      c.flag [:g, :gemfile]

      c.desc 'Path to the bundle installation directory.'
      c.default_value ENV.fetch('BUNDLE_PATH', Bundler.bundle_path.to_s)
      c.flag [:b, :'bundle-path']

      c.desc 'Gem (and dependencies) to include in the subset.'
      c.flag [:i, :include], multiple: true

      c.desc "Add an additional gem to the subset. The gem doesn't have to be part of the original Gemfile."
      c.flag [:a, :add], multiple: true

      c.desc 'Include development dependencies of subsetted gems.'
      c.default_value false
      c.switch [:d, :development]

      c.desc 'File path to output the resulting Gemfile into. Use - for standard output.'
      c.default_value '-'
      c.flag [:o, :output]

      c.action do |global_options, options, args|
        Prebundler::Cli::Subset.run(out, global_options, options, args)
      end
    end

    desc 'Generate binstubs. Accepts the same arguments as `bundle binstubs`.'
    command :binstubs do
    end

    singleton_class.send(:prepend, Module.new do
      def run(args)
        if args[0] == 'binstubs'
          exec "bundle binstubs #{args[1..-1].join(' ')}"
        else
          super
        end
      end
    end)

    pre do |global, command, options, args|
      # Pre logic here
      # Return true to proceed; false to abort and not call the
      # chosen command
      # Use skips_pre before a command to skip this block
      # on that command only
      out.silence! if global[:silent]
      load global[:config] if global[:config]
      true
    end

    post do |global, command, options, args|
      # Post logic here
      # Use skips_post before a command to skip this
      # block on that command only
    end

    on_error do |exception|
      # Error logic here
      # return false to skip default error handling
      true
    end
  end
end
