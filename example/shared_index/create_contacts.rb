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
  puts "NEW TX"
  @tx = Neo4j::Transaction.new
end

rm_db_storage
Neo4j.start

new_tx

SIZE = 100
@users = []


puts "Saving #{SIZE} users ..."
Benchmark.bm do |x|
  x.report do
    SIZE.times do |time|
      @users <<  User.new('andreas', 'ronge', 'malmoe')
      new_tx if (time % 1000) == 0
    end
  end
end

new_tx

def connect_users
  @users.each_with_index do |user, i|
    puts "I=#{i} user=#{user}"
    new_tx if (i % 1000) == 0
    100.times do |c|
      x = (c + i + 1) % SIZE
  #    puts "add user #{i} with #{x} - #{users[x]}"
      user.contact.users << @users[x]
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

result = [*Contact.find("user_id: #{@users[0].user_id} AND city: malmoe")]


puts "Found"
result.each {|x| puts "  #{x}"}

