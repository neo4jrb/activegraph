require "rubygems"
require "bundler/setup"

require 'fileutils'
require 'benchmark'
require 'neo4j'
require 'contact'


def all_contacts_for(user_id)
  [*Contact.find("user_id: #{user_id} AND city: malmoe")]
end

@count_hits = 0

def search_random
  100.times do
    # first find a user
    user_id          =(rand * SIZE).to_int
    s           = all_contacts_for(user_id)
    puts "Found #{user_id} #{s.join(', ')}"
    @count_hits += s.size # not thread safe, I know
#    puts "HIT #{s[42]}" if s
  end
end

Neo4j.start

puts "warm up"

100.times do
  id =(rand * 100).to_int
  all_contacts_for(id)
end

Benchmark.bm do |x|
  x.report do
   search_random
#    threads = []
#    50.times { threads << Thread.new { search_random } }
#    threads.each { |thread| thread.join }
  end
end

puts "Hits #{@count_hits}"
