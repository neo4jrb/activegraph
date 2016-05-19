Unique IDs
==========

The database generates unique IDs and they are accessible from all nodes and relationships using the ``neo_id`` method. These keys are somewhat volatile and may be reused or change throughout a database's lifetime, so they are unsafe to use within an application.

To work around this, you can define which key should act as primary key on ``Neo4j::ActiveNode`` classes instead of using the internal Neo4j ids. By default, ActiveNode will generate a unique ID using ``SecureRandom::uuid``. The instance methods ``id`` and ``uuid`` will both point to this.

You can define a global or per-model generation methods if you do not want to use the default. Additionally, you can change the property that will be aliased to the ``id`` method. This can be done through :doc:`Configuration </Setup>` or models themselves.

Unique IDs are **not** generated for relationships or ActiveRel models because their IDs should not be used. To query for a relationship, generate a match based from nodes. If you find yourself in situations where you need relationship IDs, you probably need to define a new ActiveNode class!

Defining your own ID
--------------------

The ``on`` parameter tells which method is used to generate the unique id.

.. code-block:: ruby

    class Person
      include Neo4j::ActiveNode
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
      include Neo4j::ActiveNode
      id_property :neo_id
    end

A note regarding constraints
----------------------------

By default, a uniqueness constraint will be set for all ID properties. To disable this, you can call ``id_property`` with ``constraint: false`` in your third param.

.. code-block:: ruby

    class Student
      include Neo4j::ActiveNode
      id_property :uuid, auto: :uuid, constraint: :false
    end

Of course, you can also use ``on: :method_name``. Omitting the ``constraint`` option will set a constraint.

Adding IDs to Existing Data
~~~~~~~~~~~~~~~~~~~~~~~~~~~

A migration task is in place if you have old or imported data in need of IDs. See the `add_id_property <https://github.com/neo4jrb/neo4j/wiki/Neo4j-v3-Migrations#add_id_property>`_ .

Working with Legacy Schemas
~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you already were using uuids, give yourself a pat on the back. Unfortunately, you may run into problems with Neo4j.rb v3. Why? By default Neo4j.rb creates a uuid index and a uuid unique constraint on every `ActiveNode`. You can change the name of the uuid by adding ``id_property`` as shown above. But, either way, you're getting ``uuid`` as a shadow index for your nodes.

If you had a property called ``uuid``, you'll have to change it or remove it since ``uuid`` is now a reserved word. If you want to keep it, your indexes will have to match the style of the default ``id_property`` (uuid index and unique).

You'll need to use the Neo4J shell or Web Interface.

**Step 1: Check Indexes and Constraints**

This command will provide a list of indexes and constraints

.. code-block:: ruby

    schema

**Step 2: Clean up any indexes that are not unique**

.. code-block:: cypher

    DROP INDEX ON :Tag(uuid);
    CREATE CONSTRAINT ON (n:Tag) ASSERT n.uuid IS UNIQUE;

**Step 3: Add an id_property to your ActiveNode**

.. code-block:: ruby

    id_property :uuid, auto: :uuid

Note: If you did not have an index or a constraint, Neo4j.rb will automatically create them for you.
