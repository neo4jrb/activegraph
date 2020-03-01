class FailingMigrationWithoutTransactions < ActiveGraph::Migrations::Base
  disable_transactions!

  def up
    execute 'MATCH (u:`User`) WHERE u.name = $name SET u.name = $new_name',
            name: 'Joe', new_name: 'Jack'
    execute 'CREATE (n:`Contact` {phone: "123123"})'
  end

  def down
    execute 'MATCH (n:`Contact` {phone: "123123"}) DELETE n'
    execute 'MATCH (u:`User`) WHERE u.name = $name SET u.name = $new_name',
            name: 'Jim', new_name: 'John'
  end
end
