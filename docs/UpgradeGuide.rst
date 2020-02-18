Upgrade Guide
=============

This guide outlines changes to major version of the Neo4j.rb gems.  For more detail about version changes, see the `neo4j gem CHANGELOG <https://github.com/neo4jrb/neo4j/blob/master/CHANGELOG.md>`_ and the `neo4j-core gem CHANGELOG <https://github.com/neo4jrb/neo4j-core/blob/master/CHANGELOG.md>`_.

Note that starting with version 9.0 of the ``neo4j`` gem and version 8.0 of the ``neo4j-core`` gem, a new practice has been enacted to release a new major / minor change in accordance with `Semantic Versioning <http://semver.org/>`_ as soon as it is warranted.  While older versions followed semantic versioning, they would contain more changes rolled up into a single version.

This upgrade guide does not cover changes before version 8.0 of the ``neo4j`` gem and version 7.0 of the ``neo4j-core`` gem.  Changes in previous versions weren't as significant and are covered in the ``CHANGELOG`` files for the respective projects.

The ``neo4j`` gem from 8.x to 9.x
---------------------------------

The ``enum`` functionality for ``ActiveNode`` and ``ActiveRel`` has been changed to be case-insensitive by default.

The ``neo4j-core`` gem from 8.x to 9.x
--------------------------------------

The ``neo4j-rake_tasks`` gem is no longer a dependency of the ``neo4j-core`` gem (which is, in turn, a dependency of the ``neo4j`` gem).  To use the rake tasks, you will need to specify the ``neo4j-rake_tasks`` gem yourself.

The ``neo4j`` gem from 7.x to 8.x and the ``neo4j-core`` gem from 6.x to 7.x
----------------------------------------------------------------------------

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

  require 'active_graph/core/cypher_session/adaptors/http'
  neo4j_adaptor = ActiveGraph::Core::CypherSession::Adaptors::HTTP.new('http://user:pass@host:port', options)
  # or
  require 'active_graph/core/cypher_session/adaptors/bolt'
  neo4j_adaptor = ActiveGraph::Core::CypherSession::Adaptors::Bolt.new('bolt://user:pass@host:port', options)
  # or
  require 'active_graph/core/cypher_session/adaptors/embedded'
  neo4j_adaptor = ActiveGraph::Core::CypherSession::Adaptors::Embedded.new('path/to/db', options)

  neo4j_session = ActiveGraph::Core::CypherSession.new(neo4j_adaptor)

With your session object, you can make queries in a number of different ways:

.. code-block:: ruby

  # Basic query
  neo4j_session.query('MATCH (n) RETURN n LIMIT 10')

  # Query with parameters
  neo4j_session.query('MATCH (n) RETURN n LIMIT {limit}', limit: 10)

Or via the `ActiveGraph::Core::Query` class

.. code-block:: ruby

  query_obj = ActiveGraph::Core::Query.new.match(:n).return(:n).limit(10)

  neo4j_session.query(query_obj)

Making multiple queries with one request is supported with the HTTP Adaptor:

.. code-block:: ruby

  results = neo4j_session.queries do
    append 'MATCH (n:Foo) RETURN n LIMIT 10'
    append 'MATCH (n:Bar) RETURN n LIMIT 5'
  end

  results[0] # results of first query
  results[1] # results of second query

When doing batched queries, there is also a shortcut for getting a new `ActiveGraph::Core::Query`:

.. code-block:: ruby

  results = neo4j_session.queries do
    append query.match(:n).return(:n).limit(10)
  end

  results[0] # result
  
With your session object, you can wrap multiple queries inside a transaction like so:

.. code-block:: ruby

  neo4j_session.transaction do |tx|
    # do stuff
    tx.mark_failed
  end

The ``neo4j`` gem
~~~~~~~~~~~~~~~~~~~~~~

Sessions
^^^^^^^^

In ``7.0`` of the ``neo4j-core`` gem, the new API doesn't have the concept of a "current" session in the way that the old API did.  If you are using ``neo4j-core``, you must keep track of whatever sessions that you open yourself.  In version ``8.0`` of the ``neo4j`` gem, however, there is a concept of a current session for your models.  Previously you might have used:

.. code-block:: ruby

  ActiveGraph::Session.current

If you are using version ``8.0`` of the ``neo4j`` gem, that will be accessible, but ``neo4j`` is no longer using that old API to have a session with Neo4j.  Instead you might use:

.. code-block:: ruby

  ActiveGraph::ActiveBase.current_session
  
Transactions
^^^^^^^^^^^^

Because of the changes to the current session API in the ``neo4j`` gem, the transactions API has also changed. Previously you might have created a transaction like so:

.. code-block:: ruby

  ActiveGraph::Transaction.run do |tx|
    # do stuff
    tx.mark_failed
  end

Now, you now interact with transactions through ``ActiveGraph::ActiveBase`` like so:

.. code-block:: ruby

  ActiveGraph::ActiveBase.run_transaction do |tx|
    # do stuff
    tx.mark_failed
  end

.. seealso::
  .. raw:: html

    Check out the ActiveBase source code to learn about some other neat helper methods <a href='https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_base.rb'>ActiveBase has</a>

server_db
^^^^^^^^^

In previous version of the ``neo4j`` gem to connect to Neo4j via HTTP you would define the value ``server_db`` in the ``neo4j.yml`` file, the ``NEO4J_TYPE`` environment variable, or a Rails configuration (``config.neo4j.session.type``).  This should now be replaced and either ``bolt`` or ``http`` should be used depending on which connection type you need.

Also, instead of using `session_type`, `session_url`, `session_path`, and `session_options`, you should use `session.type`, `session.url`, `session.path`, and `session.options` respectively.

Some examples:

.. code-block:: yaml

  # config/neo4j.yml
  # Before
  development:
    type: server_db
    url: http://localhost:7474

  # After
  development:
    type: http # or bolt
    url: http://localhost:7474

.. code-block:: ruby

  # Rails config/application.rb, config/environments/development.rb, etc...

  # Before
  config.neo4j.session_type = :server_db
  config.neo4j.session_url = 'http://localhost:7474'

  # After
  config.neo4j.session.type = :http # or :bolt
  config.neo4j.session.url = 'http://localhost:7474'

Also, there was a slight change in the way that you configure the internal faraday adaptor of the ``neo4j-core`` gem:

.. code-block:: ruby

  # Before 8.0.x of `neo4j` gem
  config.neo4j.session_options = {initialize: { ssl: { verify: true }}}

  # After 8.0.x of `neo4j` gem
  config.neo4j.session.options = {faraday_options: { ssl: { verify: true }}}

Outside of Rails
^^^^^^^^^^^^^^^^

The ``neo4j`` gem will automatically set up a number of things with it's ``railtie``.  If you aren't using Rails you may need to set some things up yourself and some of the details have changed with version 8.0 of the ``neo4j`` gem.

Previously a connection with be established with ``ActiveGraph::Session.open`` and the default session from ``neo4j-core`` would be used.  In version 7.0 of the ``neo4j-core`` gem, no such default session exists for the new API so you will need to establish a session to use the ``ActiveNode`` and ``ActiveRel`` modules like so:

.. code-block:: ruby

  adaptor = ActiveGraph::Core::CypherSession::Adaptors::HTTP.new('http://username:password@localhost:7474', wrap_level: :proc)

  session = ActiveGraph::Core::CypherSession.new(adaptor)

  ActiveGraph::ActiveBase.current_session = session

  # Or skip setting up the session yourself:

  ActiveGraph::ActiveBase.current_adaptor = adaptor

If you are using multiple threads, you should use the `on_establish_session` method to define how to setup your session.  The `current_session` is stored on a per-thread basis and if you spawn a new thread, this block will be used to establish the session for that thread:

.. code-block:: ruby

  ActiveGraph::ActiveBase.on_establish_session do
    adaptor = ActiveGraph::Core::CypherSession::Adaptors::HTTP.new('http://username:password@localhost:7474', wrap_level: :proc)

    ActiveGraph::Core::CypherSession.new(adaptor)
  end

Migrations:

If you would like to use the migrations provided by the ``neo4j`` outside of Rails you can include this in your ``Rakefile``:

.. code-block:: ruby

  load 'neo4j/tasks/migration.rake'


Indexes and Constraints
^^^^^^^^^^^^^^^^^^^^^^^

In previous versions of the ``neo4j`` gem, ``ActiveNode`` models would allow you to define indexes and constraints as part of the model.  While this was a convenient feature, it would often cause problems because Neo4j does not allow schema changes to happen in the same transaction as data changes.  This would often happen when using ``ActiveNode`` because constraints and indexes would be automatically created when your model was first loaded, which may very well be in the middle of a transaction.

In version 8.0 of the ``neo4j`` gem, you must now create indexes and constraints separately.  You can do this yourself, but version 8.0 provides fully featured migration functionality to make this easy (see the `Migrations`_ section).

If you still have indexes or constraints defined, the gem will check to see if those indexes or constraints exist.  If they don't, an exception will be raised with command that you can run to generate the appropriate migrations.  If they do exist, a warning will be given to remove the index / constraint definitions.

Also note that all ``ActiveNode`` models must have an ``id_property`` defined (which is the ``uuid`` property by default).  These constraints will also be checked and an exception will be raised if they do not exist.

Migrations
^^^^^^^^^^

Version 8.0 of the ``neo4j`` gem now includes a fully featured migration system similar to the one provided by ``ActiveRecord``.  See the :doc:`documentation <Migrations>` for details.

neo_id id_properties
^^^^^^^^^^^^^^^^^^^^

In version 8.0 of the ``neo4j`` gem support was added to allow for definining the internal Neo4j ID as the ``id_property`` for a model like so:

.. code-block:: ruby

  id_property :neo_id

.. warning::

  Use of ``neo_id`` as a perminent identifier should be done with caution.  Neo4j can recycle IDs from deleted nodes meaning that URLs or other external references using that ID will reference the wrong item.  Neo4j may be updated in the future to support internal IDs which aren't recycled, but for now use at your own risk

Exceptions
^^^^^^^^^^

With the new API comes some new exceptions which are raised.  With the new adaptor API errors are more dependable across different ways of connecting to Neo4j.

=======================================================  =========================================================================
Old Exception                                            New Exception
-------------------------------------------------------  -------------------------------------------------------------------------
ActiveGraph::Server::Resource::ServerException                 ActiveGraph::Core::CypherSession::ConnectionFailedError
ActiveGraph::Server::CypherResponse::ConstraintViolationError  ActiveGraph::Core::CypherSession::SchemaErrors::ConstraintValidationFailedError
ActiveGraph::Session::CypherError                              ActiveGraph::Core::CypherSession::CypherError
?                                                        ConstraintAlreadyExistsError
?                                                        IndexAlreadyExistsError
=======================================================  =========================================================================

