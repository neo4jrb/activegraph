Upgrade Guide
=============

Version 8.0 of the ``neo4j`` gem and version 7.0 of the ``neo4j-core`` gem introduce the most significant change to the Neo4j.rb project since version 3.0 when we introduced support for the HTTP protocol.  With this update comes a number of breaking changes which will be outlined on this page

What has changed
~~~~~~~~~~~~~~~~

The Neo4j.rb project was origionally created just to support accessing Neo4j's embedded mode Java APIs via jRuby.  In version 3.0 HTTP support was introduced, but the resulting code has been showing it's age.  An entirely new API has been created in the ``neo4j-core`` gem.  The goal of this new API is only to support making Cypher queries to Neo4j either via HTTP, Bolt (Neo4j 3.0's new binary protocol), or embedded mode in jRuby.  The old code is still around to support connecting to Neo4j via it's Java APIs, but we would like to later replace it with something simpler (perhaps in another gem).

The ``neo4j`` gem (which provides the ``ActiveNode`` and ``ActiveRel`` modules) has been refactored to use the new API in ``neo4j-core``.  Because of this if you are using ``ActiveNode``/``ActiveRel`` not much should change.

Before upgrading, the first thing that you should do is to upgrade to the latest 7.1.x version of the ``neo4j`` gem and the latest ``6.1.x`` version of the ``neo4j-core`` gem.  The upgrade from any previous gem > ``3.0`` should not be too difficult, but we are always happy to help on `Gitter <https://gitter.im/neo4jrb/neo4j>`_ or `Stackoverflow <http://stackoverflow.com/questions/ask?tags=neo4j.rb+neo4j+ruby>`_ if you are having trouble

The ``neo4j-core`` gem
~~~~~~~~~~~~~~~~~~~~~~

If you are using the ``neo4j-core`` gem without the ``neo4j`` gem, you should be able to continue using it as you have previously.  It is recommended, however, that you refactor your code to use the new API.  Some advantages of the new API:

 * The new binary protocol ("Bolt") is supported
 * You can make multiple queries at a time
 * The interface is simpler
 * Node and relationship objects don't change depending on the underlying query mechanism (Bolt/HTTP/embedded)
 * ``Path`` objects are now returned

One thing to note is that Node and Relationship objects in the new API are, by design, simple objects.  In the old API you could get relationships and other information by calling methods on node or relationship objects.  In the new API you must create Cypher queries for all data access.

The new API
^^^^^^^^^^^

To make a new session, you must first create an adaptor object and then provide it to the session ``new`` method:

.. code-block:: ruby

  neo4j_adaptor = Neo4j::Core::CypherSession::Adaptors::Bolt.new('bolt://user:pass@host:port', options)
  # or
  neo4j_adaptor = Neo4j::Core::CypherSession::Adaptors::HTTP.new('http://user:pass@host:port', options)
  # or
  neo4j_adaptor = Neo4j::Core::CypherSession::Adaptors::Embedded.new('path/to/db', options)

  neo4j_session = Neo4j::Core::CypherSession.new(neo4j_adaptor)

With your session object, you can make queries in a number of different ways:

.. code-block:: ruby

  # Basic query
  neo4j_session.query('MATCH (n) RETURN n LIMIT 10')

  # Query with parameters
  neo4j_session.query('MATCH (n) RETURN n LIMIT {limit}', limit: 10)

Or via the `Neo4j::Core::Query` class

.. code-block:: ruby

  query_obj = Neo4j::Core::Query.new.match(:n).return(:n).limit(10)

  neo4j_session.query(query_obj)

Making multiple queries with one request is support with the HTTP Adaptor:

.. code-block:: ruby

  results = neo4j_session.queries do
    append 'MATCH (n:Foo) RETURN n LIMIT 10'
    append 'MATCH (n:Bar) RETURN n LIMIT 5'
  end

  results[0] # results of first query
  results[1] # results of second query

When doing batched queries, there is also a shortcut for getting a new `Neo4j::Core::Query`:

.. code-block:: ruby

  results = neo4j_session.queries do
    append query.match(:n).return(:n).limit(10)
  end

  results[0] # result

The ``neo4j`` gem
~~~~~~~~~~~~~~~~~~~~~~

Sessions
^^^^^^^^

In ``7.0`` of the ``neo4j-core`` gem, the new API doesn't have the concept of a "current" session in the way that the old API did.  If you are using ``neo4j-core``, you must keep track of whatever sessions that you open yourself.  In version ``8.0`` of the ``neo4j`` gem, however, there is a concept of a current session for your models.  Previously you might have used:

.. code-block:: ruby

  Neo4j::Session.current

If you are using version ``8.0`` of the ``neo4j`` gem, that will be accessible, but ``neo4j`` is no longer using that old API to have a session with Neo4j.  Instead you might use:

.. code-block:: ruby

  Neo4j::ActiveBase.current_session

``server_db``
^^^^^^^^^^^^^

Indexes and Constraints
^^^^^^^^^^^^^^^^^^^^^^^

Migrations
^^^^^^^^^^



