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

Cypher
~~~~~~

Faster, but does not does not remove the database schema (indexes and constraints):

.. code-block:: ruby

  Neo4j::ActiveBase.current_session.query('MATCH (n) DETACH DELETE n')

  # For Neo4j < 2.3
  Neo4j::ActiveBase.current_session.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')

Delete data files
~~~~~~~~~~~~~~~~~

Completely delete the database files (slower, by removeds schema).  If you installed Neo4j via the rake tasks, you can run:

.. code-block:: bash

  rake neo4j:reset_yes_i_am_sure[test]

If you are using embedded Neo4j, stop embedded db, delete the db path, start embedded db.

RSpec Transaction Rollback
~~~~~~~~~~~~~~~~~~~~~~~~~~

If you are using RSpec you can perform tests in a transaction as you would using active record. Just add the following to your rspec configuration in ``spec/rails_helper.rb`` or ``spec/spec_helper.rb``

.. code-block:: ruby

  config.around do |example|
    Neo4j::Transaction.run do |tx|
      example.run
        tx.mark_failed
      end
    end

Using Rack::Test
~~~~~~~~~~~~~~~~

If you're using the `Rack::Test <https://github.com/rack-test/rack-test>` gem to test your Neo4j-enabled web application from the outside, be aware that the `Rack::Test::Methods` mixin won't work with this driver.  Instead, use the `Rack::Test::Session` approach as described in the `Sinatra documentation <http://sinatrarb.com/testing.html>`.
