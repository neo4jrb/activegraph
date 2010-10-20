class Role
  include Neo4j::RelationshipMixin
  # notice that neo4j relationships can also have properties
  property :name
end

class Movie
end

class Actor
  include Neo4j::NodeMixin

  # The following line defines the acted_in relationship
  # using the following classes:
  # Actor[Node] --(Role[Relationship])--> Movie[Node]
  #
  has_n(:acted_in).to(Movie).relationship(Role)

  index :name, :type => :fulltext
end


class Director
  include Neo4j::NodeMixin
  property :name
  has_n(:directed).to(Movie)
end

class Movie
  include Neo4j::NodeMixin
  property :title
  property :year

  has_one(:director).from(Director, :directed)

  # defines a method for traversing incoming acted_in relationships from Actor
  has_n(:actors).from(Actor, :acted_in)

  index :title, :via => :actors, :type => :fulltext
end