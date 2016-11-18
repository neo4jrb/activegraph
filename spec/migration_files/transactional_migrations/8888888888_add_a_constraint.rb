class AddAConstraint < Neo4j::Migrations::Base
  def up
    add_constraint :Book, :some
  end

  def down
    drop_constraint :Book, :some
  end
end
