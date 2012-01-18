class FooBar
  include Neo4j::NodeMixin

  has_n :bar
end

class SubFooBar < FooBar

end

class Domain < Neo4j::Rails::Model
  property :name
  ref_node { Neo4j.default_ref_node }
end

class SubSubFooBar < FooBar

end

class Person < Neo4j::Rails::Model
  property :name
  property :domain
end

class Project < Neo4j::Rails::Model
  property :name
  index :name
  property :domain

  has_n(:people).to(Person)
end


class SubProject < Project

end