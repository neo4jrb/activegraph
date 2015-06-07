Rake Tasks
==========

The ``neo4j-core`` gem (automatically included with the ``neo4j`` gem) includes some rake tasks which make it easy to install and manage a Neo4j server in the same directory as your Ruby project.

.. glossary::

  .. _rake_tasks-neo4j_install:

  **neo4j:install**
    **Arguments:** ``version`` and ``environment`` (environment default is `development`)

    **Example:** ``rake neo4j:install[community-2.2.2,development]``

    Downloads and installs Neo4j into ``$PROJECT_DIR/db/neo4j/<environment>/``

  .. _rake_tasks-neo4j_config:

  **neo4j:config**
    **Arguments:** ``environment`` and ``port``

    **Example:** ``rake neo4j:config[development,7000]``

    Configure the port which Neo4j runs on.  This affects the HTTP REST interface and the web console address.

  .. _rake_tasks-neo4j_start:

  **neo4j:start**
    **Arguments:** ``environment``

    **Example:** ``rake neo4j:start[development]``

    Start the Neo4j server

  .. _rake_tasks-neo4j_start_no_wait:

  **neo4j:start_no_wait**
    **Arguments:** ``environment``

    **Example:** ``rake neo4j:start_no_wait[development]``

    Start the Neo4j server with the ``start-no-wait`` command

  .. _rake_tasks-neo4j_stop:

  **neo4j:stop**
    **Arguments:** ``environment``

    **Example:** ``rake neo4j:stop[development]``

    Stop the Neo4j server


