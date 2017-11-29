$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'prebundler/version'

Gem::Specification.new do |s|
  s.name     = 'prebundler'
  s.version  = ::Prebundler::VERSION
  s.authors  = ['Cameron Dutro']
  s.email    = ['camertron@gmail.com']
  s.homepage = 'http://github.com/camertron'

  s.description = s.summary = 'Gem dependency prebuilder'

  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true

  s.add_dependency 'parallel'
  s.add_dependency 'gli'

  # @TODO: remove these
  s.add_dependency 'aws-sdk', '~> 2.0'
  s.add_dependency 'pry-byebug'

  s.executables << 'prebundle'

  s.require_path = 'lib'
  s.files = Dir['{lib,spec}/**/*', 'Gemfile', 'CHANGELOG.md', 'README.md', 'Rakefile', 'prebundler.gemspec']
end
