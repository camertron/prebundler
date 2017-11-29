module Prebundler
  module Cli
    class List < Base
      def run
        gem_list.each do |_, gem_ref|
          next unless show_gem?(gem_ref)
          out.puts "#{gem_ref.id} from #{gem_ref.source}"
        end
      end

      private

      def show_gem?(gem_ref)
        return true if options[:source].empty?
        options[:source].any? { |source| gem_ref.source.include?(source) }
      end

      def gem_list
        @gem_list ||= Prebundler::GemfileInterpreter.interpret(gemfile_path, bundle_path)
      end

      def gemfile_path
        options.fetch(:gemfile)
      end

      def bundle_path
        nil  # not necessary for resolution
      end
    end
  end
end
