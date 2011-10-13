require 'rubygems'
require 'fileutils'
require 'benchmark'
require "bundler/setup"
require 'neo4j'
require 'contact'


def rm_db_storage
  FileUtils.rm_rf Neo4j::Config[:storage_path]
  raise "Can't delete db" if File.exist?(Neo4j::Config[:storage_path])
end

def finish_tx
  return unless @tx
  @tx.success
  @tx.finish
  @tx = nil
end

def new_tx
  finish_tx if @tx
  @tx = Neo4j::Transaction.new
end

rm_db_storage
Neo4j.start

new_tx



puts "Saving #{SIZE} users ..."
Benchmark.bm do |x|
  x.report do
    SIZE.times do |user_id|
      User.new('andreas', user_id, 'malmoe')
      new_tx if (user_id % 1000) == 0
    end
  end
end

new_tx

def connect_users
  SIZE.times do |user_id|
    user = User.find("user_id: #{user_id}").first
    puts "found user #{user} (#{user_id})"
    new_tx if (user_id % 1000) == 0
    FRIEND_SIZE.times do 
      friend_user_id = (rand * SIZE).to_int
      next if friend_user_id == user_id
      other_user = User.find("user_id: #{friend_user_id}").first

      puts "  connect with user #{other_user}"
      user.contact.users << other_user
    end
  end
end

puts "Connect users"
Benchmark.bm do |x|
  x.report do
    connect_users
  end
end


finish_tx
SIZE.times do |user_id|
  found = Contact.find("user_id: #{user_id} AND city: malmoe")
  puts "Found for #{user_id} #{[*found].join(', ')}"
end


puts "SEARCH !!!"


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
