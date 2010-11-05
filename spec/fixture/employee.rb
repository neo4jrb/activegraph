# forward declaration
#class Person
#  include Neo4j::NodeMixin
#end


class Employee < Person
  property :employee_id

  has_n :contracts

end
