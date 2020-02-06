class RenameBobFrank < Neo4j::Migrations::Base
  def up
    execute 'MATCH (u:`User`) WHERE u.name = $name SET u.name = $new_name',
            name: 'Bob', new_name: 'Frank'
  end

  def down
    execute 'MATCH (u:`User`) WHERE u.name = $name SET u.name = $new_name',
            name: 'Frank', new_name: 'Bob'
  end
end
