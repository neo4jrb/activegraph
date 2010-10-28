class Employee < Person
  property :employee_id

  has_n :contracts

end
