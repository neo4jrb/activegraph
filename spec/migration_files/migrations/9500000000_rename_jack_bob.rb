class RenameJackBob < Neo4j::Migrations::Base
  def up
    execute 'MATCH (u:`User`) WHERE u.name = $name SET u.name = $new_name',
            name: 'Jack', new_name: 'Bob'
  end

  def down
    execute 'MATCH (u:`User`) WHERE u.name = $name SET u.name = $new_name',
            name: 'Bob', new_name: 'Jack'
  end
end
