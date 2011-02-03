require "rubygems"
require "bundler/setup"
require 'fileutils'
require 'neo4j'


class Movie
  include Neo4j::NodeMixin
  rule(:all)
end


class Role
  include Neo4j::RelationshipMixin
  property :title, :character

  index :title

  def to_s
    "Role id #{neo_id} title '#{self.title}' character '#{self.character}'"
  end
end

class Actor
  include Neo4j::NodeMixin
  rule(:all)
  property :name
  has_n(:acted_in).to(Movie).relationship(Role)
  index :name

  def to_s
    "Actor id:#{neo_id} name: '#{self.name}'"
  end
end

class Movie
  property :title
  property :year

  # defines a method for traversing incoming acted_in relationships from Actor
  has_n(:actors).from(Actor, :acted_in)

  index :title
  index :year
  
  def to_s
    "Movie id:#{neo_id} title: '#{self.title}'"
  end
end