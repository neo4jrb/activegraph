Migrations
==========

Neo4j does not have a set schema like relational databases, but sometimes changes to the schema and the data are required. To help with this, Neo4j.rb provides an ``ActiveRecord``-like migration framework and a set of helper methods to manipulate both database schema and data.  Just like ``ActiveRecord``, a record of which transactions have been run will be stored in the database so that a migration is automatically only run once per environment.

.. note::

  If you are new to Neo4j, note that properties on nodes and relationships are not defined ahead of time.  Properties can be added and removed on the fly, and so adding a ``property`` to your ``Node`` or ``Relationship`` model is sufficient to start storing data.  No migration is needed to add properties, but if you remove a property from your model you may want a migration to cleanup the data (by using the ``remove_property``, for example).

.. note::

  The migration functionality described on this page was introduced in version 8.0 of the ``neo4j`` gem.

Generators
----------

Migrations can be created by using the built-in Rails generator:

.. code-block:: bash

  rails generate neo4j:migration RenameUserNameToFirstName

This will generate a new file located in ``db/neo4j/migrate/xxxxxxxxxx_rename_user_name_to_first_name.rb``

.. code-block:: ruby

  class RenameUserNameToFirstName < ActiveGraph::Migrations::Base
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

  class SomeMigration < ActiveGraph::Migrations::Base
    disable_transactions!

    ...
  end

The schema file
---------------

When generating an empty database for your app you could run all of your migrations, but this strategy gets slower over time and can even cause issues if your older migrations become incompatible with your newer code.  For this reason, whenever you run migrations a ``db/neo4j/schema.yml`` file is created which keeps track of constraints, indexes (which aren't automatically created by constraints), and which migrations have been run.  This schema file can then be loaded with the ``neo4j:schema:load`` rake task to quickly and safely setup a blank database for testing or for a new environment.  While the ``neo4j:migrate`` rake task automatically creates the ``schema.yml`` file, if you ever need to generate it yourself you can use the ``neo4j:schema:dump`` rake task.

It is suggested that you check in the ``db/neo4j/schema.yml`` to your repository whenever you have new migrations.

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

neo4j:schema:dump
~~~~~~~~~~~~~~~~~

Reads the current database and generates a ``db/neo4j/schema.yml`` file to track constraints, indexes, and migrations which have been run (runs automatically after the ``neo4j:migrate`` task)

.. code-block:: bash

    rake neo4j:schema:dump

neo4j:schema:load
~~~~~~~~~~~~~~~~~

Reads the ``db/neo4j/schema.yml`` file and loads the constraints, indexes, and migration nodes into the database.  The default behavior is to only add, but an argument can be passed in to tell the task to remove any indexes / constraints that were found in the database which were not in the ``schema.yml`` file.

.. code-block:: bash

    rake neo4j:schema:load
    rake neo4j:schema:load[true] # Remove any constraints or indexes which aren't in the ``schema.yml`` file


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

An alias for ``ActiveGraph::Session.query``. You can use it as root for the query builder:

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

Use `force: true` as an option in the third argument to ignore errors about an already existing constraint.


#drop_constraint
~~~~~~~~~~~~~~~~

Drops an unique constraint on a given label attribute.

**Warning** it would fail if you make data changes in the same migration. To fix, define ``disable_transactions!`` in your migration file.

.. code-block:: ruby

  drop_constraint(:User, :name)

Use `force: true` as an option in the third argument to ignore errors about the constraint being missing.

#add_index
~~~~~~~~~~

Adds a new exact index on a given label attribute.

**Warning** it would fail if you make data changes in the same migration. To fix, define ``disable_transactions!`` in your migration file.

.. code-block:: ruby

  add_index(:User, :name)

Use `force: true` as an option in the third argument to ignore errors about an already existing index.

#drop_index
~~~~~~~~~~~

Drops an exact index on a given label attribute.

**Warning** it would fail if you make data changes in the same migration. To fix, define ``disable_transactions!`` in your migration file.

.. code-block:: ruby

  drop_index(:User, :name)

Use `force: true` as an option in the third argument to ignore errors about the index being missing.

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

.. code-block:: ruby

  populate_id_property :User

Check :doc:`Adding IDs to Existing Data </UniqueIDs>` for more usage details.


#relabel_relation
~~~~~~~~~~~~~~~~~~~~~~~

Relabels a relationship, keeping intact any relationship attribute.

.. code-block:: ruby

  relabel_relation :old_label, :new_label

Additionally you can specify the starting and the destination node, using ``:from`` and ``:to``.

You can specify also the ``:direction`` (one if ``:in``, ``:out`` or ``:both``).

Example:

.. code-block:: ruby

  relabel_relation :friends, :FRIENDS, from: :Animal, to: :Person, direction: :both


#change_relations_style
~~~~~~~~~~~~~~~~~~~~~~~

Relabels relationship nodes from one format to another.

Usage:

.. code-block:: ruby

  change_relations_style list_of_labels, old_style, new_style


For example, if you created a relationship ``#foo`` in 3.x, and you want to convert it to the 4.x+ ``foo`` syntax, you could run this.

.. code-block:: ruby

  change_relations_style [:all, :your, :labels, :here], :lower_hash, :lower

Allowed styles are:

* ``:lower``: lowercase string, like ``my_relation``
* ``:upper``: uppercase string, like ``MY_RELATION``
* ``:lower_hash``: Lowercase string starting with hash, like ``#my_relation``
