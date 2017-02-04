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
