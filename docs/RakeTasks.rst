Rake Tasks
==========

The ``neo4j-core`` gem (automatically included with the ``neo4j`` gem) includes some rake tasks which make it easy to install and manage a Neo4j server in the same directory as your Ruby project.

.. note::
  If you are using zsh, you need to prefix any rake tasks with arguments with the noglob command, e.g. ``$ noglob bundle exec rake neo4j:install[community-latest]``.

.. glossary::

  .. _rake_tasks-neo4j_install:

  **neo4j:install**
    **Arguments:** ``version`` and ``environment`` (environment default is `development`)

    **Example:** ``rake neo4j:install[community-latest,development]``

    Downloads and installs Neo4j into ``$PROJECT_DIR/db/neo4j/<environment>/``

    For the ``version`` argument you can specify either ``community-latest``/``enterprise-latest`` to get the most up-to-date stable version or you can specify a specific version with the format ``community-x.x.x``/``enterprise-x.x.x``

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

  **neo4j:start**
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

Migrations
----------

RelabelRelationships
~~~~~~~~~~~~~~~~~~~~

.. note::
  This strips properties from the relationship nodes! Only run this if you're okay with that.

This relabels relationship nodes from one format to another.
For example, if you created a relationship ``#foo`` in 3.x,
and you want to convert it to the 4.x+ ``foo`` syntax, you could
run this.

Usage:

.. code-block:: bash

    rake neo4j:migrate[relabel_relationships,setup]
    # Edit the file generated in db/neo4j-migrate/relabel_relationships.yml
    rake neo4j:migrate[relabel_relationships]

Configuring the YAML:

.. code-block:: yaml

    # Change all these relationships from 3.x `#style` to the new `style`
    relationships: [enrolled_in,lessons]
    formats:
      old: lower_hashtag
      new: lower


.. code-block:: yaml

    # Change a single relationship from `lowercase` to `UPPERCASE`
    relationships: [some_rels]
    formats:
      old: lower
      new: upper
