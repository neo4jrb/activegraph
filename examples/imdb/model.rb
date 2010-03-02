
class Movie; end


class Role
  include Neo4j::RelationshipMixin
  property :title, :character
  
  def to_s
    "Role title #{self.title} character #{self.character}"
  end
end

class Actor
  include Neo4j::NodeMixin
  property :name
  has_n(:acted_in).to(Movie).relationship(Role)
  index :name, :tokenized => true

  def to_s
    "Actor #{self.name}"
  end
end

class Movie
  include Neo4j::NodeMixin
  property :title
  property :year

  # defines a method for traversing incoming acted_in relationships from Actor
  has_n(:actors).from(Actor, :acted_in)
  
  def to_s
    "Movie #{self.title}"
  end
end

