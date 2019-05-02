def test(one:, two: nil)
    puts "one: #{one}"
    puts "two: #{two}"
end

test({}.tap do |o|
    o[:one] = 1
    o[:two] = ENV["TEST_TWO"] if ENV["TEST_TWO"]
end)
