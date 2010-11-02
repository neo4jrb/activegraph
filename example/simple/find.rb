require 'person'


if ARGV.size != 2
  puts "ruby find.rb <property> <value>"
else
  key    = ARGV[0]
  value  = ARGV[1]
  found = Person.find("#{key}: #{value}")
  if !found.empty?
    puts "Found #{[*found].join(', ')}"
  else
    puts "Not found person with #{key} == #{value}"
  end
end

