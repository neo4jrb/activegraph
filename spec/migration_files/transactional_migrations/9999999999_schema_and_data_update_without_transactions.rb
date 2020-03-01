class SchemaAndDataUpdateWithoutTransactions < ActiveGraph::Migrations::Base
  disable_transactions!

  def up
    add_constraint :Book, :isbn
    execute 'CREATE (n:`Contact` {phone: "123123"})'
  end

  def down
    fail ActiveGraph::IrreversibleMigration
  end
end
