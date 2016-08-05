class SchemaAndDataUpdateWithoutTransactions < Neo4j::Migrations::Base
  disable_transactions!

  def up
    add_constraint :Book, :isbn
    execute 'CREATE (n:`Contact` {phone: "123123"})'
  end

  def down
    fail Neo4j::IrreversibleMigration
  end
end
