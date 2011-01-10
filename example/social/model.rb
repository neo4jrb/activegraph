class City < Neo4j::Rails::Model

end

class State < Neo4j::Rails::Model
  property :name
  index :name

  has_n(:cities).to(City)

  def self.create(state_name)
    instance = super()
    instance.name = state_name
    instance.save!
    instance
  end

  def to_s
    "State #{name}"
  end

end

class Person < Neo4j::Rails::Model

end

class City < Neo4j::Rails::Model
  property :name
  index :name

  has_n(:people).to(Person)
  has_one(:state).from(State, :cities)

  def self.create(city_name, state)
    instance = super()
    instance.name = city_name
    instance.state = state
    instance.save!
    instance
  end

  def to_s
    "City #{name} state: #{state}"
  end
end



class Person < Neo4j::Rails::Model
  property :name
  index :name
  has_n :likes
  has_n :friends
  has_one(:city).from(City, :people)

  def self.create(name, city)
    instance = super(:name => name)
    instance.city = city
    instance.save!
    instance
  end

  def to_s
    name
  end

end

class Film < Neo4j::Rails::Model
  property :title
  index :title
  
  def self.create(title)
    super(:title => title)
  end

  def to_s
    "Film #{title}"
  end

end


