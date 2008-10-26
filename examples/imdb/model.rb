class Movie; end

class Role
  include Neo4j::Relation
  properties :title, :character
  
  def to_s
    self.title if property?('title')
    self.character if property?('character')
  end
end

class Actor
  include Neo4j::Node
  properties :name
  has_n(:acted_in).to(Movie).relation(Role)

  index :name
end

class Movie
  include Neo4j::Node
  properties :title
  properties :year

  # defines a method for traversing incoming acted_in relationships from Actor
  has_n(:actors).from(Actor, :acted_in)
end

