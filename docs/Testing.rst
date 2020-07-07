Testing
=======

To run your tests, you must have a Neo4j server running (ideally a different server than the development database on a different port).  One quick way to get a test database up and running is to use the built in rake task:

.. code-block:: bash

  rake neo4j:install[community-latest,test]
  # or a specific version
  rake neo4j:install[community-3.1.0,test]

You can configure it to respond on a different port like so:

.. code-block:: bash

  rake neo4j:config[test,7475]

If you are using Rails, you can edit the test configuration ``config/environments/test.rb`` or the ``config/neo4j.yml`` file (see :doc:`Setup <Setup>`)

How to clear the database
-------------------------

Cypher DELETE
~~~~~~~~~~~~~

This is the most reliable way to clear your database in Neo4j

.. code-block:: cypher

  // For version of Neo4j after 2.3.0
  // DETACH DELETE takes care of removing relationships for you
  MATCH (n) DETACH DELETE n

In Ruby:

.. code-block:: ruby

  ActiveGraph::Base.query('MATCH (n) DETACH DELETE n')

If you are using ``Node`` and/or ``Relationship`` from the ``activegraph`` gem you will no doubt have ``SchemaMigration`` nodes in the database.  If you delete these nodes the gem will complain that your migrations haven't been run.  To get around this you could modify the query to exclude those nodes:

.. code-block:: cypher

  MATCH (n) WHERE NOT n:`ActiveGraph::Migrations::SchemaMigration`
  DETACH DELETE n

The ``database_cleaner`` gem
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``database_cleaner`` gem is a popular and useful tool for abstracting away the cleaning of databases in tests.  There is support for Neo4j in the ``database_cleaner`` gem, but there are a couple of problems with it:

 * Neo4j does not currently support truncation (wiping of the entire database designed to be faster than a ``DELETE``)
 * Neo4j supports transactions, but nested transactions do not work the same as in relational databases. (see below)

Because of this, all strategies in the ``database_cleaner`` gem amount to it's "Deletion" strategy.  Therefore, while you are welcome to use the ``database_cleaner`` gem, is is generally simpler to execute one of the above Cypher queries.

Delete data files
~~~~~~~~~~~~~~~~~

Completely delete the database files (slower, by removeds schema).  If you installed Neo4j via the ``neo4j-rake_tasks`` gem, you can run:

.. code-block:: bash

  rake neo4j:reset_yes_i_am_sure[test]

If you are using embedded Neo4j, stop embedded db, delete the db path, start embedded db.

RSpec Transaction Rollback
~~~~~~~~~~~~~~~~~~~~~~~~~~

If you are using RSpec you can perform tests in a transaction as you would using ActiveRecord. Just add the following to your rspec configuration in ``spec/rails_helper.rb`` or ``spec/spec_helper.rb``

.. code-block:: ruby

  # For the `neo4j` gem
  config.around do |example|
    ActiveGraph::Base.transaction do |tx|
      example.run
      tx.failure
    end
  end

There is one big disadvantage to this approach though: In Neo4j, nested transactions still act as one big transaction.  If the code you are testing has a transaction which, for example, gets marked as failed, then the transaction around the RSpec example will be marked as failed.

Using Rack::Test
~~~~~~~~~~~~~~~~

If you're using the `Rack::Test <https://github.com/rack-test/rack-test>` gem to test your Neo4j-enabled web application from the outside, be aware that the `Rack::Test::Methods` mixin won't work with this driver.  Instead, use the `Rack::Test::Session` approach as described in the `Sinatra documentation <http://sinatrarb.com/testing.html>`.
