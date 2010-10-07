class Book < Neo4j::Model
  has_one(:author).to(Person)
  has_n(:pages).to(Person)

  accepts_nested_attributes_for :author, :pages
end
