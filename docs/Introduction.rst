Introduction
============

ActiveGraph is an ActiveRecord-inspired OGM (Object Graph Mapping, like
`ORM <http://en.wikipedia.org/wiki/Object-relational_mapping>`_) for Ruby supporting Neo4j 3.4+.

Terminology
-----------

Neo4j
~~~~~

Node
  An `Object or Entity <http://en.wikipedia.org/wiki/Object_%28computer_science%29>`_ which has a distinct identity.
  Can store arbitrary properties with values

Label
  A means of identifying nodes.  Nodes can have zero or more labels.  While similar in concept to relational table names, nodes can have multiple labels (i.e. a node could have the labels ``Person`` and ``Teacher``)

Relationship
  A link from one node to another.  Can store arbitrary properties with values.  A direction is required but relationships can be traversed bi-directionally without a performance impact.

Type
  Relationships always have exactly one **type** which describes how it is relating it's source and destination nodes (i.e. a relationship with a ``FRIEND_OF`` type might connect two ``Person`` nodes)

ActiveGraph
~~~~~~~~~~~

ActiveGraph consists of the `activegraph` gem and suitable driver at level 1.7.x. There are currently 2 such available
drivers gems: `neo4j-ruby-driver` and `neo4j-java-driver` (jruby only). Both drivers implement exactly the same api and
can be swapped seamlessly on jruby.

activegraph
  Provides ``Node`` and ``Relationship`` modules for object modeling.  Introduces *Model* and *Association* concepts (see below).

drivers
  Provide low-level connectivity, transactions, and response object wrapping with api and functionality consistent with
  the official neo4j drivers. Please see https://github.com/neo4jrb/neo4j-ruby-driver/tree/1.7

Model
  A Ruby class including either the ``ActiveGraph::Node`` module (for modeling nodes) or the ``ActiveGraph::Relationship`` module (for modeling relationships) from the ``neo4j`` gem.  These modules give classes the ability to define properties, associations, validations, and callbacks

Association
  Defined on an ``Node`` model.  Defines either a ``has_one`` or ``has_many`` relationship to a model.  A higher level abstraction of a **Relationship**

Code Examples
-------------

With ActiveGraph, you can use either high-level abstractions for convenience or low level APIs for flexibility.

Node
~~~~~~~~~~

Node provides an Object Graph Model (OGM) for abstracting Neo4j concepts with an ``ActiveRecord``-like API:

.. code-block:: ruby

  # Models to create nodes
  person = Person.create(name: 'James', age: 15)

  # Get object by attributes
  person = Person.find_by(name: 'James', age: 15)

  # Associations to traverse relationships
  person.houses.map(&:address)

  # Method-chaining to build and execute queries
  Person.where(name: 'James').order(age: :desc).first

  # Query building methods can be chained with associations
  # Here we get other owners for pre-2005 vehicles owned by the person in question
  person.vehicles(:v).where('v.year < 2005').owners(:other).to_a

Setup
-----

See the next section for instructions on :doc:`Setup </Setup>`
