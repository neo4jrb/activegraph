Migrations
==========

Neo4j does not have a set schema like relational databases, but sometimes changes to the schema and the data are required. To help with this, Neo4j.rb provides an ``ActiveRecord``-like migration framework and a set of helper methods to manipulate both database schema and data.


Generators
----------

Migrations can be created by using the built-in Rails generator:

.. code-block:: bash

  rails generate neo4j:migration RenameUserNameToFirstName

This will generate a new file located in ``db/neo4j/migrate/xxxxxxxxxx_rename_user_name_to_first_name.rb``

.. code-block:: ruby

  class RenameUserNameToFirstName < Neo4j::Migrations::Base
    def up
      rename_property :User, :name, :first_name
    end

    def down
      rename_property :User, :first_name, :name
    end
  end

In the same way as ``ActiveRecord`` does, you should fill up the ``up`` and ``down`` methods to define the migration and (eventually) the rollback steps.


Transactions
------------
Every migrations runs inside a transaction by default. So, if some statement fails inside a migration fails, the database rollbacks to the previous state.

However this behaviour is not always good. For instance, neo4j doesn't allow schema and data changes in the same transaction.

To disable this, you can use the ``disable_transactions!`` helper in your migration definition:

.. code-block:: ruby

  class SomeMigration < Neo4j::Migrations::Base
    disable_transactions!

    ...
  end

Tasks
-----
Neo4j.rb implements a clone of the ``ActiveRecord`` migration tasks API to migrate.


neo4j:migrate:all
~~~~~~~~~~~~~~~~~

Runs any pending migration.

.. code-block:: bash

    rake neo4j:migrate:all

neo4j:migrate
~~~~~~~~~~~~~

An alias for ``rake neo4j:migrate:all``.

.. code-block:: bash

    rake neo4j:migrate:all


neo4j:migrate:up
~~~~~~~~~~~~~~~~

Executes a migration given it's version id.

.. code-block:: bash

    rake neo4j:migrate:up VERSION=some_version

neo4j:migrate:down
~~~~~~~~~~~~~~~~~~

Reverts a migration given it's version id.

.. code-block:: bash

    rake neo4j:migrate:down VERSION=some_version

neo4j:migrate:status
~~~~~~~~~~~~~~~~~~~~

Prints a detailed migration state report, showing up and down migrations together with their own version id.

.. code-block:: bash

    rake neo4j:migrate:status


neo4j:rollback
~~~~~~~~~~~~~~

Reverts the last up migration. You can additionally pass a ``STEPS`` parameter, specifying how many migration you want to revert.

.. code-block:: bash

    rake neo4j:rollback


Integrate Neo4j.rb with ActiveRecord migrations
-----------------------------------------------

You can setup Neo4j migration tasks to run together with standard ActiveRecord ones. Simply create a new rake task in ``lib/tasks/neo4j_migrations.rake``:

.. code-block:: ruby

    Rake::Task['db:migrate'].enhance ['neo4j:migrate']

This will run the ``neo4j:migrate`` every time you run a ``rake db:migrate``

Migration Helpers
------------------

#execute
~~~~~~~~

Executes a pure neo4j cypher query, interpolating parameters.

.. code-block:: ruby

  execute('MATCH (n) WHERE n.name = {node_name} RETURN n', node_name: 'John')

.. code-block:: ruby

  execute('MATCH (n)-[r:`friend`]->() WHERE n.age = 7 DELETE r')


#query
~~~~~~

An alias for ``Neo4j::Session.query``. You can use it as root for the query builder:

.. code-block:: ruby

  query.match(:n).where(name: 'John').delete(:n).exec


#remove_property
~~~~~~~~~~~~~~~~

Removes a property given a label.

.. code-block:: ruby

  remove_property(:User, :money)

#rename_property
~~~~~~~~~~~~~~~~

Renames a property given a label.

.. code-block:: ruby

  rename_property(:User, :name, :first_name)

#drop_nodes
~~~~~~~~~~~

Removes all nodes with a certain label

.. code-block:: ruby

  drop_nodes(:User)

#add_label
~~~~~~~~~~

Adds a label to nodes, given their current label

.. code-block:: ruby

  add_label(:User, :Person)

#add_labels
~~~~~~~~~~~

Adds labels to nodes, given their current label

.. code-block:: ruby

  add_label(:User, [:Person, :Boy])

#remove_label
~~~~~~~~~~~~~

Removes a label from nodes, given a label

.. code-block:: ruby

  remove_label(:User, :Person)

#remove_labels
~~~~~~~~~~~~~~

Removes labels from nodes, given a label

.. code-block:: ruby

  remove_label(:User, [:Person, :Boy])

#rename_label
~~~~~~~~~~~~~

Renames a label

.. code-block:: ruby

  rename_label(:User, :Person)

#add_constraint
~~~~~~~~~~~~~~~

Adds a new unique constraint on a given label attribute.

**Warning** it would fail if you make data changes in the same migration. To fix, define ``disable_transactions!`` in your migration file.

.. code-block:: ruby

  add_constraint(:User, :name)


#drop_constraint
~~~~~~~~~~~~~~~~

Drops an unique constraint on a given label attribute.

**Warning** it would fail if you make data changes in the same migration. To fix, define ``disable_transactions!`` in your migration file.

.. code-block:: ruby

  drop_constraint(:User, :name)


#add_index
~~~~~~~~~~

Adds a new exact index on a given label attribute.

**Warning** it would fail if you make data changes in the same migration. To fix, define ``disable_transactions!`` in your migration file.

.. code-block:: ruby

  add_index(:User, :name)


#drop_index
~~~~~~~~~~~

Drops an exact index on a given label attribute.

**Warning** it would fail if you make data changes in the same migration. To fix, define ``disable_transactions!`` in your migration file.

.. code-block:: ruby

  drop_index(:User, :name)


#say
~~~~

Writes some text while running the migration.

:Ruby:
  .. code-block:: ruby

    say 'Hello'

:Output:
  .. code-block:: ruby

    -- Hello

When passing ``true`` as second parameter, it writes it more indented.

:Ruby:
  .. code-block:: ruby

    say 'Hello', true

:Output:
  .. code-block:: ruby

      -> Hello

#say_with_time
~~~~~~~~~~~~~~

Wraps a set of statements inside a block, printing the given and the execution time. When an ``Integer`` is returned, it assumes it's the number of affected rows.

:Ruby:
  .. code-block:: ruby

    say_with_time 'Trims all names' do
      query.match(n: :User).set('n.name = TRIM(n.name)').pluck('count(*)').first
    end

:Output:
  .. code-block:: bash

    -- Trims all names.
       -> 0.3451s
       -> 2233 rows

#populate_id_property
~~~~~~~~~~~~~~~~~~~~~

Populates the ``uuid`` property (or any ``id_property`` you defined) of nodes given their model name.

:Ruby:
  .. code-block:: ruby

    populate_id_property :User

Check :doc:`Adding IDs to Existing Data </UniqueIDs>` for more usage details.
