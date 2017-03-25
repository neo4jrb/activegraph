Miscellany
==========


Mass / Batch Importing
~~~~~~~~~~~~~~~~~~~~~~

Importing many nodes or relationships at once is a common use case.  Often the naive approach can be slow because each query is done over a separate HTTP request.  There are a number of ways to improve this:

 * The `neo4j-core <https://github.com/neo4jrb/neo4j-core>`_ gem (starting with version 7.0) supports batch execution of queries by calling the `queries` method an a `CypherSession` (There is not yet a means of doing this in `ActiveNode` and `ActiveRecord` in the `neo4j` gem)
 * Since even batched queries require sending a large payload of queries, you might consider making a single Cypher query with an array `parameter <http://neo4j.com/docs/developer-manual/current/cypher/syntax/parameters/>`_ which can be turned into a series of rows with the `UNWIND <http://neo4j.com/docs/developer-manual/current/cypher/clauses/unwind/>`_ clause which can then be used to execute a `CREATE <https://neo4j.com/docs/developer-manual/current/cypher/clauses/create/>`_ clause to make one creation per row from the `UNWIND`
 * The `neo4apis <https://github.com/neo4jrb/neo4apis>`_ gem offers a way to create a DSL for defining and loading data and will batch creations for you (see the `neo4apis-github <https://github.com/neo4jrb/neo4apis-github>`_ and `neo4apis-twitter <https://github.com/neo4jrb/neo4apis-twitter>`_ gems for examples of implementing a `neo4apis` DSL)

Outside of Ruby, there are also standard ways of importing large sets of data:

 * The `LOAD CSV <http://neo4j.com/docs/developer-manual/current/cypher/clauses/load-csv/>`_ clause allows you to take a CSV in any format and create your own custom Cypher logic to import the data
 * The Neo4j `import tool <http://neo4j.com/docs/operations-manual/current/tutorial/import-tool/>`_ requires a specific CSV format for nodes and relationships, but it can be extremely fast.  (Note that the import tool can only be used to create a new database, not to add to an existing one)

Cleaning Your Database for Testing
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Often when writing tests for Neo4j it is desirable to start with a fresh database for each test.  In general this can be as easy as writing a Cypher query which runs before each test:

.. code-block:: cypher

  // For version of Neo4j before 2.3.0
  // Nodes cannot be deleted without first deleting their relationships
  MATCH (n)
  OPTIONAL MATCH (n)-[r]-()
  DELETE n,r

  // For version of Neo4j before 2.3.0
  // DETACH DELETE takes care of removing relationships for you
  MATCH (n) DETACH DELETE n

In Ruby:

.. code-block:: ruby

  # Just using the `neo4j-core` gem:
  neo4j_session.query('MATCH (n) DETACH DELETE n')

  # When using the `neo4j` gem:
  Neo4j::ActiveBase.current_session.query('MATCH (n) DETACH DELETE n')

If you are using ``ActiveNode`` and/or ``ActiveRel`` from the ``neo4j`` gem you will no doubt have ``SchemaMigration`` nodes in the database.  If you delete these nodes the gem will complain that your migrations haven't been run.  To get around this you could modify the query to exclude those nodes:

.. code-block:: cypher
  MATCH (n) WHERE NOT n:`Neo4j::Migrations::SchemaMigration`
  DETACH DELETE n

Separately, the ``database_cleaner`` gem is a popular and useful tool for abstracting away the cleaning of databases in tests.  There is support for Neo4j in the ``database_cleaner`` gem, but there are a couple of problems with it:

 * Neo4j does not currently support truncation (wiping of the entire database designed to be faster than a ``DELETE``)
 * Neo4j supports transactions, but nested transactions do not work the same as in relational databases.  A failure in a nested transaction will cause the entire set of outer transactions to be rolled back.  Therefore running tests inside of a transaction and rolling back a nested transaction for each test isn't viable.

Because of this, all strategies in the ``database_cleaner`` gem amount to it's "Deletion" strategy.  Therefore, while you are welcome to use the ``database_cleaner`` gem, is is generally simpler to execute one of the above Cypher queries.
