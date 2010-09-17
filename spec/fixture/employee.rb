puts "EMPLOYEE"
class Employee < Person
  property :employee_id

  has_n :contracts

  # TODO
  def indexer
    Neo4j::Index::Indexer.new(Person)
  end
end
puts "EMPLOYEE DONE"