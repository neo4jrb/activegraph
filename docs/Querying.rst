Querying
========

Simple Query Methods
--------------------

There are a number of ways to find and return nodes.

``.find``
~~~~~~~~~

Find an object by `id_property` **(TODO: LINK TO id_property documentation)**

``.find_by``
~~~~~~~~~~~~

``find_by`` and ``find_by!`` behave as they do in ActiveRecord, returning the first object matching the criteria or nil (or an error in the case of ``find_by!``)

.. code-block:: ruby

  Post.find_by(title: 'Neo4j.rb is awesome')

Scope Method Chaining
---------------------

Like in ActiveRecord you can build queries via method chaining.  This can start in one of three ways:

 * ``Model.all``
 * ``Model.association``
 * ``model_object.association``

In the case of the association calls, the scope becomes a class-level representation of the association's model so far.  So for example if I were to call ``post.comments`` I would end up with a representation of nodes from the ``Comment`` model, but only those which are related to the ``post`` object via the ``comments`` association.

At this point it should be mentioned that what associations return isn't an ``Array`` but in fact an ``AssociationProxy``.  ``AssociationProxy`` is ``Enumerable`` so you can still iterate over it as a collection.  This allows for the method chaining to build queries, but it also enables :ref:`eager loading <active_node-eager_loading>` of associations

From a scope you can filter, sort, and limit to modify the query that will be performed or call a further association.

Querying the scope
~~~~~~~~~~~~~~~~~~

Similar to ActiveRecord you can perform various operations on a scope like so:

.. code-block:: ruby

  lesson.teachers.where(name: /.* smith/i, age: 34).order(:name).limit(2)

The arguments to these methods are translated into ``Cypher`` query statements.  For example in the above statement the regular expression is translated into a Cypher ``=~`` operator.  Additionally all values are translated into Neo4j `query parameters <http://neo4j.com/docs/stable/cypher-parameters.html>`_ for the best performance and to avoid query injection attacks.

Chaining associations
~~~~~~~~~~~~~~~~~~~~~

As you've seen, it's possible to chain methods to build a query on one model.  In addition it's possible to also call associations at any point along the chain to transition to another associated model.  The simplest example would be:

.. code-block:: ruby

  student.lessons.teachers

This would returns all of the teachers for all of the lessons which the students is taking.  Keep in mind that this builds only one Cypher query to be executed when the result is enumerated.  Finally you can combine scoping and association chaining to create complex cypher query with simple Ruby method calls.

.. code-block:: ruby

  student.lessons(:l).where(level: 102).teachers(:t).where('t.age > 34').pluck(:l)

Here we get all of the lessons at the 102 level which have a teacher older than 34.  The ``pluck`` method will actually perform the query and return an ``Array`` result with the lessons in question.  There is also a ``return`` method which returns an ``Array`` of result objects which, in this case, would respond to a call to the ``#l`` method to return the lesson.

Note here that we're giving an argument to the associaton methods (``lessons(:l)`` and ``teachers(:t)``) in order to define Cypher variables which we can refer to.  In the same way we can also pass in a second argument to define a variable for the relationship which the association follows:


.. code-block:: ruby

  student.lessons(:l, :r).where("r.start_date < {the_date} and r.end_date >= {the_date}").params(the_date: '2014-11-22').pluck(:l)

Here we are limiting lessons by the ``start_date`` and ``end_date`` on the relationship between the student and the lessons.  We can also use the ``rel_where`` method to filter based on this relationship:

.. code-block:: ruby

  student.lessons.where(subject: 'Math').rel_where(grade: 85)


.. seealso::

  .. raw:: html

    There is also a screencast available reviewing association chaining:

    <iframe width="560" height="315" src="https://www.youtube.com/embed/pUAl9ov22j4" frameborder="0" allowfullscreen></iframe>

Associations and Unpersisted Nodes
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

There is some special behavior around association creation when nodes are new and unsaved. Below are a few scenarios and their outcomes.

When both nodes are persisted, associations changes using ``<<`` or ``=`` take place immediately -- no need to call save.

.. code-block:: ruby

  student = Student.first
  Lesson = Lesson.first
  student.lessons << lesson

In that case, the relationship would be created immediately.

When the node on which the association is called is unpersisted, no changes are made to the database until ``save`` is called. Once that happens, a cascading save event will occur.

.. code-block:: ruby

  student = Student.new
  lesson = Lesson.first || Lesson.new
  # This method will not save `student` or change relationships in the database:
  student.lessons << lesson

Once we call ``save`` on ``student``, two or three things will happen:

* Since ``student`` is unpersisted, it will be saved
* If ``lesson`` is unpersisted, it will be saved
* Once both nodes are saved, the relationship will be created

This process occurs within a transaction. If any part fails, an error will be raised, the transaction will fail, and no changes will be made to the database.

Finally, if you try to associate an unpersisted node with a persisted node, the unpersisted node will be saved and the relationship will be created immediately:

.. code-block:: ruby

  student = Student.first
  lesson = Lesson.new
  student.lessons << lesson

In the above example, ``lesson`` would be saved and the relationship would be created immediately. There is no need to call ``save`` on ``student``.


Parameters
~~~~~~~~~~

If you need to use a string in where, you should set the parameter manually.

.. code-block:: ruby

  Student.all.where("s.age < {age} AND s.name = {name} AND s.home_town = {home_town}")
    .params(age: params[:age], name: params[:name], home_town: params[:home_town])
    .pluck(:s)

Variable-length relationships
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Introduced in version 5.1.0**

It is possible to specify a variable-length qualifier to apply to relationships when calling association methods.

.. code-block:: ruby

  student.friends(rel_length: 2)

This would find the friends of friends of a student. Note that you can still name matched nodes and relationships and use those names to build your query as seen above:

.. code-block:: ruby

  student.friends(:f, :r, rel_length: 2).where('f.gender = {gender} AND r.since >= {date}').params(gender: 'M', date: 1.month.ago)


.. note::

  You can either pass a single options Hash or provide **both** the node and relationship names along with the optional Hash.


There are many ways to provide the length information to generate all the various possibilities Cypher offers:

.. code-block:: ruby

  # As a Fixnum:
  ## Cypher: -[:`FRIENDS`*2]->
  student.friends(rel_length: 2)

  # As a Range:
  ## Cypher: -[:`FRIENDS`*1..3]->
  student.friends(rel_length: 1..3) # Get up to 3rd degree friends

  # As a Hash:
  ## Cypher: -[:`FRIENDS`*1..3]->
  student.friends(rel_length: {min: 1, max: 3})

  ## Cypher: -[:`FRIENDS`*0..]->
  student.friends(rel_length: {min: 0})

  ## Cypher: -[:`FRIENDS`*..3]->
  student.friends(rel_length: {max: 3})

  # As the :any Symbol:
  ## Cypher: -[:`FRIENDS`*]->
  student.friends(rel_length: :any)


.. caution::
  By default, "\*..3" is equivalent to "\*1..3"  and "\*" is equivalent to "\*1..", but this may change
  depending on your Node4j server configuration. Keep that in mind when using variable-length
  relationships queries without specifying a minimum value.


.. note::
  When using variable-length relationships queries on `has_one` associations, be aware that multiple nodes
  could be returned!


The Query API
-------------

The ``neo4j-core`` gem provides a ``Query`` class which can be used for building very specific queries with method chaining.  This can be used either by getting a fresh ``Query`` object from a ``Session`` or by building a ``Query`` off of a scope such as above.

.. code-block:: ruby

  Neo4j::Session.current.query # Get a new Query object

  # Get a Query object based on a scope
  Student.query_as(:s)
  student.lessons.query_as(:l)

The ``Query`` class has a set of methods which map directly to Cypher clauses and which return another ``Query`` object to allow chaining.  For example:

.. code-block:: ruby

  student.lessons.query_as(:l) # This gives us our first Query object
    .match("l-[:has_category*]->(root_category:Category)").where("NOT(root_category-[:has_category]->()))
    .pluck(:root_category)

Here we can make our own ``MATCH`` clauses unlike in model scoping.  We have ``where``, ``pluck``, and ``return`` here as well in addition to all of the other clause-methods.  See `this page <https://github.com/neo4jrb/neo4j-core/wiki/Queries>`_ for more details.

**TODO Duplicate this page and link to it from here (or just duplicate it here):**
https://github.com/neo4jrb/neo4j-core/wiki/Queries

.. seealso::
  .. raw:: html

    There is also a screencast available reviewing deeper querying concepts:

    <iframe width="560" height="315" src="https://www.youtube.com/embed/UFiWqPdH7io" frameborder="0" allowfullscreen></iframe>

#proxy_as
---------

Sometimes it makes sense to turn a ``Query`` object into (or back into) a proxy object like you would get from an association.  In these cases you can use the `Query#proxy_as` method:

.. code-block:: ruby

  student.query_as(:s)
    .match("(s)-[rel:FRIENDS_WITH*1..3]->(s2:Student")
    .proxy_as(Student, :s2).lessons

Here we pick up the `s2` variable with the scope of the `Student` model so that we can continue calling associations on it.

``match_to`` and ``first_rel_to``
---------------------------------

There are two methods, match_to and first_rel_to that both make simple patterns easier.

In the most recent release, match_to accepts nodes; in the master branch and in future releases, it will accept a node or an ID. It is essentially shorthand for association.where(neo_id: node.neo_id) and returns a QueryProxy object.

.. code-block:: ruby

  # starting from a student, match them to a lesson based off of submitted params, then return students in their classes
  student.lessons.match_to(params[:id]).students

first_rel_to will return the first relationship found between two nodes in a QueryProxy chain.

.. code-block:: ruby

  student.lessons.first_rel_to(lesson)
  # or in the master branch, future releases
  student.lessons.first_rel_to(lesson.id)

This returns a relationship object.

Finding in Batches
------------------

Finding in batches will soon be supported in the neo4j gem, but for now is provided in the neo4j-core gem (documentation)

Orm_Adapter
-----------

You can also use the orm_adapter API, by calling #to_adapter on your class. See the API, https://github.com/ianwhite/orm_adapter

Find or Create By...
--------------

QueryProxy has a ``find_or_create_by`` method to make the node rel creation process easier. Its usage is simple:

.. code-block:: ruby

  a_node.an_association(params_hash)

The method has branching logic that attempts to match an existing node and relationship. If the pattern is not found, it tries to find a node of the expected class and create the relationship. If *that* doesn't work, it creates the node, then creates the relationship. The process is wrapped in a transaction to prevent a failure from leaving the database in an inconsistent state.

There are some mild caveats. First, it will not work on associations of class methods. Second, you should not use it across more than one associations or you will receive an error. For instance, if you did this:

.. code-block:: ruby

  student.friends.lessons.find_or_create_by(subject: 'Math')

Assuming the ``lessons`` association points to a ``Lesson`` model, you would effectively end up with this:

.. code-block:: ruby

  math = Lesson.find_or_create_by(subject: 'Math')
  student.friends.lessons << math

...which is invalid and will result in an error.
