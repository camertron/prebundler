module Prebundler
  module Cli
    class Subset < Base
      def run
        subset = Prebundler::GemfileSubset.from(options[:gemfile], bundle_path)

        options[:include].each { |g| subset.include(g) }
        options[:add].each { |a| subset.add_raw(a, group: 'https://rubygems.org') }

        result = subset.to_gemfile(include_dev_deps: options[:development])

        if options[:output].strip == '-'
          out.write(result)
        else
          File.write(options[:output], result)
        end
      end

      private

      def bundle_path
        options.fetch(:'bundle-path')
      end
    end
  end
end
