require 'bundler'
require 'prebundler'
require 'pry-byebug'

# gems = Prebundler::GemfileInterpreter.interpret('./Gemfile', '/bundle').gems
gf = Prebundler::GemfileInterpreter.interpret('/Users/cameron/workspace/lumos_rails/Gemfile', '/Users/cameron/.rbenv/versions/2.4.2/lib/ruby/gems/2.4.0')
binding.pry
puts 'foo'
