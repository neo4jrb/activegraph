class SchemaAndDataUpdate < Neo4j::Migrations::Base
  def up
    add_constraint :Book, :isbn
    execute 'CREATE (n:`Contact` {phone: "123123"})'
  end

  def down
    fail Neo4j::IrreversibleMigration
  end
end
