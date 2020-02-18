Unique IDs
==========

The database generates unique IDs and they are accessible from all nodes and relationships using the ``neo_id`` method. These keys are somewhat volatile and may be reused or change throughout a database's lifetime, so they are unsafe to use within an application.

Neo4j.rb requires you to define which key should act as primary key on ``ActiveGraph::Node`` classes instead of using the internal Neo4j ids. By default, Node will generate a unique ID using ``SecureRandom::uuid`` saving it in a ``uuid`` property. The instance method ``id`` will also point to this.

You can define a global or per-model generation methods if you do not want to use the default. Additionally, you can change the property that will be aliased to the ``id`` method. This can be done through :doc:`Configuration </Configuration>` or models themselves.

Unique IDs are **not** generated for relationships or Relationship models because their IDs should not be used. To query for a relationship, generate a match based from nodes. If you find yourself in situations where you need relationship IDs, you probably need to define a new Node class!

Defining your own ID
--------------------

The ``on`` parameter tells which method is used to generate the unique id.

.. code-block:: ruby

    class Person
      include ActiveGraph::Node
      id_property :personal_id, on: :phone_and_name

      property :name
      property :phone

      def phone_and_name
        self.name + self.phone # strange example ...
      end
    end

Using internal Neo4j IDs as id_property
---------------------------------------

Even if using internal Neo4j ids is not recommended, you can configure your model to use it:

.. code-block:: ruby

    class Person
      include ActiveGraph::Node
      id_property :neo_id
    end

A note regarding constraints
----------------------------

A constraint is required for the ``id_property`` of an ``Node`` model.  To create constraints, you can run the following command:

.. code-block:: bash

  rake neo4j:generate_schema_migration[constraint,Model,uuid]

Replacing ``Model`` with your model name and ``uuid`` with another ``id_property`` if you have specified something else.  When you are ready you can run the migrations:

.. code-block:: bash

  rake neo4j:migrate

If you forget to do this, an exception will be raised giving you the appropriate command to generate the migration.

Adding IDs to Existing Data
---------------------------

If you have old or imported data in need of IDs, you can use the built-in ``populate_id_property`` migration helper.

Just create a new migration like this and run it:

.. code-block:: bash

    rails g neo4j:migration PopulateIdProperties

.. code-block:: ruby

    class PopulateIdProperties < ActiveGraph::Migrations::Base
      def up
        populate_id_property :MyModel
      end

      def down
        raise IrreversibleMigration
      end
    end

It will load the model, find its given ID property and generation method, and populate that property on all nodes of that class where an ``id_property`` is not already assigned. It does this in batches of up to 900 at a time by default, but this can be changed with the ``MAX_PER_BATCH`` environment variable (batch time taken standardized per node will be shown to help you tune batch size for your DB configuration).

Working with Legacy Schemas
---------------------------

If you already were using uuids, give yourself a pat on the back. Unfortunately, you may run into problems with Neo4j.rb v3. Why? By default Neo4j.rb requires a uuid index and a uuid unique constraint on every `Node`. You can change the name of the uuid by adding ``id_property`` as shown above. But, either way, you're getting ``uuid`` as a shadow index for your nodes.

If you had a property called ``uuid``, you'll have to change it or remove it since ``uuid`` is now a reserved word. If you want to keep it, your indexes will have to match the style of the default ``id_property`` (uuid index and unique).

You'll need to use the Neo4J shell or Web Interface.

**Step 1: Check Indexes and Constraints**

This command will provide a list of indexes and constraints

.. code-block:: ruby

    schema

**Step 2: Clean up any indexes that are not unique using a migration**

.. code-block:: bash

    rails g neo4j:migration AddConstraintToTag

.. code-block:: ruby

    class AddConstraintToTag < ActiveGraph::Migrations::Base
      def up
        drop_index :Tag, :uuid
        add_constraint :Tag, :uuid
      end

      def down
        drop_constraint :Tag, :uuid
        add_index :Tag, :uuid
      end
    end

**Step 3: Add an id_property to your Node**

.. code-block:: ruby

    id_property :uuid, auto: :uuid

Note: If you did not have an index or a constraint, Neo4j.rb will automatically create them for you.
