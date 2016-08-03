class AddAConstraint < Neo4j::Migrations::Base
  def up
    add_constraint :Book, :isbn
  end

  def down
    remove_constraint :Book, :isbn
  end
end
