require 'prebundler'
require 'pry-byebug'

gf = Prebundler::GemfileInterpreter.interpret('/Users/cameron/workspace/lumos_rails/Gemfile')
puts gf.each.to_a
