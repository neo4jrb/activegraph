class RenameJohnJack < ActiveGraph::Migrations::Base
  def up
    execute 'MATCH (u:`User`) WHERE u.name = $name SET u.name = $new_name',
            name: 'John', new_name: 'Jack'
  end

  def down
    fail ActiveGraph::IrreversibleMigration
  end
end
