ActiveRel
=========

ActiveRel is a module in the ``neo4j`` gem which wraps relationships. ActiveRel objects share most of their behavior with ActiveNode objects. ActiveRel is purely optional and offers advanced functionality for complex relationships.

When to Use?
------------

It is not always necessary to use ActiveRel models but if you have the need for validation, callback, or working with properties on unpersisted relationships, it is the solution.

Note that in Neo4j it isn't possible to access relationships except by first accessing a node.  Thus ``ActiveRel`` doesn't implement a ``uuid`` property like ``ActiveNode``.

... Documentation notes

  Separation of relationship logic instead of shoehorning it into Node models

  Validations, callbacks, custom methods, etc.

  Centralize relationship type, no longer need to use ``:type`` or ``:origin`` options in models

Setup
-----

ActiveRel model definitions have four requirements:

 * include Neo4j::ActiveRel
 * call from_class with a valid model constant or :any
 * call to_class with a valid model constant or :any
 * call type with a Symbol or String to define the Neo4j relationship type

See the note on from/to at the end of this page for additional information.

.. code-block:: ruby

    # app/models/enrolled_in.rb
    class EnrolledIn
      include Neo4j::ActiveRel
      before_save :do_this

      from_class :Student
      to_class   :Lesson
      type 'enrolled_in'

      property :since, type: Integer
      property :grade, type: Integer
      property :notes

      validates_presence_of :since

      def do_this
        #a callback
      end
    end

.. seealso::
  .. raw:: html

    There is also a screencast available reviewing ActiveRel:

    <iframe width="560" height="315" src="https://www.youtube.com/embed/f7NNGIWZ1pE" frameborder="0" allowfullscreen></iframe>

Relationship Creation
---------------------

From an ActiveRel Model
~~~~~~~~~~~~~~~~~~~~~~~

Once setup, ActiveRel models follow the same rules as ActiveNode in regard to properties. Declare them to create setter/getter methods. You can also set ``created_at`` or ``updated_at`` for automatic timestamps.

ActiveRel instances require related nodes before they can be saved. Set these using the from_node and to_node methods.

.. code-block:: ruby

    rel = EnrolledIn.new
    rel.from_node = student
    rel.to_node = lesson

You can pass these as parameters when calling new or create if you so choose.

.. code-block:: ruby

    rel = EnrolledIn.new(from_node: student, to_node: lesson)
    #or
    rel = EnrolledIn.create(from_node: student, to_node: lesson)

From a `has_many` or `has_one` association
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Add the :rel_class option to an association with the name of an ActiveRel model. Association creation and querying will use this rel class, verifying classes, adding defaults, and performing callbacks.

.. code-block:: ruby

    class Student
      include Neo4j::ActiveNode
      has_many :out, :lessons, rel_class: :EnrolledIn
    end

Creating Unique Relationships
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``creates_unique`` class method will change the Cypher generated during rel creation from ``CREATE`` to ``CREATE UNIQUE``. It may be called with one optional argument of the following:

* ``:none``, also used when no argument is given, will not include properties to determine whether ot not to create a unique relationship. This means that no more than one relationship of the same pairing of nodes, rel type, and direction will ever be created.
* ``:all``, which will include all set properties in rel creation. This means that if a new relationship will be created unless all nodes, type, direction, and rel properties are matched.
* ``{on: [keys]}`` will use the keys given to determine whether to create a new rel and the remaining properties will be set afterwards.

Query and Loading existing relationships
----------------------------------------

Like nodes, you can load relationships a few different ways.

:each_rel, :each_with_rel, or :pluck methods
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Any of these methods can return relationship objects.

.. code-block:: ruby

    Student.first.lessons.each_rel { |r| }
    Student.first.lessons.each_with_rel { |node, rel| }
    Student.first.query_as(:s).match('(s)-[rel1:\`enrolled_in\`]->(n2)').pluck(:rel1)

These are available as both class or instance methods. Because both each_rel and each_with_rel return enumerables when a block is skipped, you can take advantage of the full suite of enumerable methods:

.. code-block:: ruby

    Lesson.first.students.each_with_rel.select{ |n, r| r.grade > 85 }

Be aware that select would be performed in Ruby after a Cypher query is performed. The example above performs a Cypher query that matches all students with relationships of type enrolled_in to Lesson.first, then it would call select on that.

Accessing related nodes
-----------------------

Once a relationship has been wrapped, you can access the related nodes using from_node and to_node instance methods. Note that these cannot be changed once a relationship has been created.

.. code-block:: ruby

    student = Student.first
    lesson = Lesson.first
    rel = EnrolledIn.create(from_node: student, to_node: lesson, since: 2014)
    rel.from_node
    => #<Neo4j::ActiveRel::RelatedNode:0x00000104589d78 @node=#<Student property: 'value'>>
    rel.to_node
    => #<Neo4j::ActiveRel::RelatedNode:0x00000104589d50 @node=#<Lesson property: 'value'>>

As you can see, this returns objects of type RelatedNode which delegate to the nodes. This allows for lazy loading when a relationship is returned in the future: the nodes are not loaded until you interact with them, which is beneficial with something like each_with_rel where you already have access to the nodes and do not want superfluous calls to the server.

Advanced Usage
--------------

Separation of Relationship Logic
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

ActiveRel really shines when you have multiple associations that share a relationship type. You can use an ActiveRel model to separate the relationship logic and just let the node models be concerned with the labels of related objects.

.. code-block:: ruby

    class User
      include Neo4j::ActiveNode
      property :managed_stats, type: Integer #store the number of managed objects to improve performance

      has_many :out, :managed_lessons,  model_class: :Lesson,  rel_class: :ManagedRel
      has_many :out, :managed_teachers, model_class: :Teacher, rel_class: :ManagedRel
      has_many :out, :managed_events,   model_class: :Event,   rel_class: :ManagedRel
      has_many :out, :managed_objects,  model_class: false,    rel_class: :ManagedRel

      def update_stats
        managed_stats += 1
        save
      end
    end

    class ManagedRel
      include Neo4j::ActiveRel
      after_create :update_user_stats
      validate :manageable_object
      from_class :User
      to_class :any
      type 'manages'

      def update_user_stats
        from_node.update_stats
      end

      def manageable_object
        errors.add(:to_node) unless to_node.respond_to?(:managed_by)
      end
    end

    # elsewhere
    rel = ManagedRel.new(from_node: user, to_node: any_node)
    if rel.save
      # validation passed, to_node is a manageable object
    else
      # something is wrong
    end

Additional methods
------------------

``:type`` instance method, ``_:type`` class method: return the relationship type of the model

``:_from_class`` and ``:_to_class`` class methods: return the expected classes declared in the model

Regarding: from and to
----------------------

``:from_node``, ``:to_node``, ``:from_class``, and ``:to_class`` all have aliases using ``start`` and ``end``: ``:start_class``, ``:end_class``, ``:start_node``, ``:end_node``, ``:start_node=``, ``:end_node=``. This maintains consistency with elements of the Neo4j::Core API while offering what may be more natural options for Rails users.
