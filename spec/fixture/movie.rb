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
end

class Movie
  include Neo4j::NodeMixin
  property :title
  property :year

  # defines a method for traversing incoming acted_in relationships from Actor
  has_n(:actors).from(Actor, :acted_in)
end