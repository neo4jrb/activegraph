require 'rubygems'
require 'neo4j'
require 'tx_util'

class Person
  include Neo4j::NodeMixin
  has_n :friends
  property :name
  property :born
  index :name, :type => :fulltext

  rule(:senior, :trigger => :readers){ born < 1950}
  rule(:loner, :trigger => :readers){ friends.count == 0}
  rule(:socialite){ friends.count > 1}

  def to_s
    "Person #{name} born: #{born}"
  end
end

class NewsStory
  include Neo4j::NodeMixin
  property :title
  property :text
  has_n :readers

  # a rule for which story has more then 1 senior reader
  rule(:senior_readers) { readers.find_all{|person| person.senior?}.size > 0}
  # a rule for which story has more then 1 loner
  rule(:loner_readers) { readers.find_all{|person| person.loner?}.size > 0}

  def to_s
    "Story #{title}"
  end
end


# Create an transaction
new_tx

# Create two persons
jimmy = Person.new(:name => 'jimmy', :born => 1940)
james = Person.new(:name => 'james', :born => 1980)

# James thinks he is a friend of Jimmy, but Jimmy does not consider James as his friend
james.friends << jimmy

# Create a news story
neo_news = NewsStory.new :title=>"Neo4j News"

# Add readers for the Neo News story
neo_news.readers << jimmy << james

# Create another news story
ruby_news = NewsStory.new :title=>"Ruby News"

ruby_news.readers << james

# Let the event framework run the rules
finish_tx

puts "Find all people being senior"
Person.senior.each{|p| puts p} #=> [jimmy] (an enumerable)

puts "jimmy.loner?=#{jimmy.loner?}" # => true
puts "james.loner?=#{james.loner?}" # => false

puts "Find all News Stories which have loners as readers (jimmy is a loner)"
NewsStory.loner_readers.each {|n| puts n} # => [ruby_news] since only jimmy is reader of that news


puts "Find person named 'andreas'"
person = Person.find('name: james', :type => :fulltext).first
puts "person=#{person}"

puts "Traverse james friends friends"
person.friends.depth(2).each{|n| puts n} # => an enumerable of friends friends.

Neo4j.shutdown