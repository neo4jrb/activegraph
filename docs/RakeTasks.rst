Rake Tasks
==========

The ``neo4j-rake_tasks`` gem includes some rake tasks which make it easy to install and manage a Neo4j server in the same directory as your Ruby project.

.. glossary::

  .. _rake_tasks-neo4j_generate_schema_migration:

  **neo4j:generate_schema_migration**
    **Arguments**
      Either the string `index` or the string `constraint`

      The Neo4j label

      The property

    **Example:** rake neo4j:generate_schema_migration[constraint,Person,uuid]

    Creates a migration which force creates either a constraint or an index in the database for the given label / property pair.  When you create a model the gem will require that a migration be created and run and it will give you the appropriate rake task in the exception.

  .. _rake_tasks-neo4j_install:

  **neo4j:install**
    **Arguments:** ``version`` and ``environment`` (environment default is `development`)

    **Example:** ``rake neo4j:install[community-latest,development]``

    Downloads and installs Neo4j into ``$PROJECT_DIR/db/neo4j/<environment>/``

    For the ``version`` argument you can specify either ``community-latest``/``enterprise-latest`` to get the most up-to-date stable version or you can specify a specific version with the format ``community-x.x.x``/``enterprise-x.x.x``

    A custom download URL can be specified using the ``NEO4J_DIST`` environment variable like ``NEO4J_DIST=http://dist.neo4j.org/neo4j-VERSION-unix.tar.gz``

  .. _rake_tasks-neo4j_config:

  **neo4j:config**
    **Arguments:** ``environment`` and ``port``

    **Example:** ``rake neo4j:config[development,7100]``

    Configure the port which Neo4j runs on.  This affects the HTTP REST interface and the web console address.  This also sets the HTTPS port to the specified port minus one (so if you specify 7100 then the HTTP port will be 7099)

  .. _rake_tasks-neo4j_start:

  **neo4j:start**
    **Arguments:** ``environment``

    **Example:** ``rake neo4j:start[development]``

    Start the Neo4j server

    Assuming everything is ok, point your browser to http://localhost:7474 and the Neo4j web console should load up.

  .. _rake_tasks-neo4j_start_no_wait:

  **neo4j:shell**
    **Arguments:** ``environment``

    **Example:** ``rake neo4j:shell[development]``

    Open a Neo4j shell console (REPL shell).

    If Neo4j isn't already started this task will first start the server and shut it down after the shell is exited.

  **neo4j:start_no_wait**
    **Arguments:** ``environment``

    **Example:** ``rake neo4j:start_no_wait[development]``

    Start the Neo4j server with the ``start-no-wait`` command

  .. _rake_tasks-neo4j_stop:

  **neo4j:stop**
    **Arguments:** ``environment``

    **Example:** ``rake neo4j:stop[development]``

    Stop the Neo4j server

  **neo4j:restart**
    **Arguments:** ``environment``

    **Example:** ``rake neo4j:restart[development]``

    Restart the Neo4j server
