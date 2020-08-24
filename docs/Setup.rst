Setup
===========

The ``activegraph`` gem supports both Ruby and JRuby and can be used with many different frameworks and services.

Below are some instructions on how to get started:

Ruby on Rails
~~~~~~~~~~~~~

The following contains instructions on how to setup ActiveGraph with Rails.
If you prefer a video to follow along you can use `this YouTube video <https://www.youtube.com/watch?v=bDjbqRL9HcM>`_

There are two ways to add neo4j to your Rails project.  You can :ref:`generate a new project<generating-new-app>` with ActiveGraph as the default model mapper or you can :ref:`add it manually<add-gem-to-existing-project>`.

.. _generating-new-app:

Generating a new app
^^^^^^^^^^^^^^^^^^^^

To create a new Rails app with Neo4j as the default model mapper use ``-m`` to run a script from the Neo4j project and ``-O`` to exclude ActiveRecord like so:

.. code-block:: bash

  rails new myapp -O -m https://raw.githubusercontent.com/neo4jrb/activegraph/master/docs/activegraph.rb

An example series of setup commands:

.. code-block:: bash

  rails new myapp -O -m https://raw.githubusercontent.com/neo4jrb/activegraph/master/docs/activegraph.rb
  cd myapp
  rake neo4j:install[community-4.0.6]
  db/neo4j/development/bin/neo4j-admin set-initial-password password
  rake neo4j:start
  rails generate scaffold User name:string email:string
  rake neo4j:migrate
  rails s
  open http://localhost:3000/users

.. seealso::

  .. raw:: html

    There is also a screencast available demonstrating how to set up a new Rails app:

    <iframe width="560" height="315" src="https://www.youtube.com/embed/n0P0pOP34Mw" frameborder="0" allowfullscreen></iframe>

.. _add-gem-to-existing-project:

Adding the gem to an existing project
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Include in your ``Gemfile``:

.. code-block:: ruby

  # for rubygems
  gem 'activegraph', '~> 10.0.0' # For example, see https://rubygems.org/gems/activegraph/versions for the latest versions
  gem 'neo4j-ruby-driver', '~> 1.7.0'

In ``application.rb``:

.. code-block:: ruby

  require 'active_graph/railtie'

.. note::

  ActiveGraph does not interfere with ActiveRecord and both can be used in the same application

If you want the ``rails generate`` command to generate ActiveGraph models by default you can modify ``application.rb`` like so:

.. code-block:: ruby

  class Application < Rails::Application
    # ...

    config.generators { |g| g.orm :active_graph }
  end

Rails configuration
^^^^^^^^^^^^^^^^^^^

For both new apps and existing apps there are multiple ways to configure how to connect to neo4j.  You can use environment variables, the ``config/neo4j.yml`` file, or configure via the Rails application config.

For environment variables:

.. code-block:: bash

  NEO4J_URL=bolt://localhost:7687

For the ``config/neo4j.yml`` file:

.. code-block:: yaml

  development:
    url: neo4j://localhost:7687

  test:
    url: neo4j://localhost:7688

  production:
    url:
      - neo4j://core1:7687
      - neo4j://core2:7687
      - neo4j://core3:7687
    username: neo4j
    password: password


The `railtie` provided by the `neo4j` gem will automatically look for and load this file.

You can also use your Rails configuration.  The following example can be put into ``config/application.rb`` or any of your environment configurations (``config/environments/(development|test|production).rb``) file:

.. code-block:: ruby

  config.neo4j.driver.url = 'bolt://localhost:7687'

Neo4j requires authentication by default but if you install using the built-in :doc:`rake tasks </RakeTasks>`) authentication is disabled.  If you are using authentication you can configure it like this:

.. code-block:: ruby

  config.neo4j.driver.url = 'neo4j://localhost:7687'
  config.neo4j.driver.username = 'neo4j'
  config.neo4j.driver.password = 'password'

In Neo4j 4.x encryption is not configured by default, while neo4j-ruby-driver 1.7 by default requests encrypted connection. To make both work together either setup SSL on the neo4j server or disable encryption in the driver:

.. code-block:: ruby

  config.neo4j.driver.encryption = false


Any Ruby Project
~~~~~~~~~~~~~~~~

Include ``activegrah`` and either ``neo4j-ruby-driver`` or ``neo4j-java-driver`` in your ``Gemfile``:

.. code-block:: ruby

  gem 'activegraph', '>= 10.0.0' # For example, see https://rubygems.org/gems/activegraph/versions for the latest versions
  gem 'neo4j-ruby-driver' # For example, see https://rubygems.org/gems/neo4j-ruby-driver/versions for the latest versions

.. code-block:: ruby

  # Both are optional

  # To provide tasks to install/start/stop/configure Neo4j
  require 'active_graph/rake_tasks'
  # Comes from the `neo4j-rake_tasks` gem

If you don't already have a server you can install one with the rake tasks from ``neo4j_server.rake``.  See the (:doc:`rake tasks documentation </RakeTasks>`) for details on how to install, configure, and start/stop a Neo4j server in your project directory.

Driver Instance
^^^^^^^^^^^^^^^

To start interacting with neo4j a driver instance is required:

In Ruby
```````

When the railtie is included, this happens automatically.

Using the ``acivegraph`` gem (``Node`` and ``Relationship``) without Rails
``````````````````````````````````````````````````````````````````````````

To define your own driver for the ``activegraph`` gem you create a driver object and establish it as the
default driver with the ``Base`` module (this is done automatically in Rails):

.. code-block:: ruby

  ActiveGraph::Base.driver = Neo4j::Driver::GraphDatabase.driver('neo4j::/localhost:7687', Neo4j::Driver.AuthTokens.basic('user','pass'), encryption: false)

Driver instances are thread-safe. Session and transactions can be created explicitly to guarantee reading your own
writes and atomic operations with the following methods:

.. code-block:: ruby

  ActiveGraph::Base.session
  ActiveGraph::Base.write_transaction
  ActiveGraph::Base.read_transaction

In the absense of those method calls ``activegraph`` automatically creates a session and write transaction and
associates them with the thread.

What if I'm integrating with a pre-existing Neo4j database?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When trying to get the ``activegraph`` gem to integrate with a pre-existing Neo4j database instance (common in cases of
migrating data from a legacy SQL database into a Neo4j-powered rails app), remember that every ``Node`` model is
required to have an ID property with a ``unique`` constraint upon it, and that unique ID property will default to
``uuid`` unless you override it to use a different ID property.

This commonly leads to getting a ``ActiveGraph::DeprecatedSchemaDefinitionError`` in Rails when attempting to access a
node populated into a Neo4j database directly via Cypher (i.e. when Rails didn't create the node itself). To solve or
avoid this problem, be certain to define and constrain as unique a uuid property (or whatever other property you want
Rails to treat as the unique ID property) in Cypher when loading the legacy data or use the methods discussed in
:doc:`Unique IDs </UniqueIDs>`.

Heroku
~~~~~~

Add a Neo4j db to your application:

.. code-block:: bash

  # To use GrapheneDB:
  heroku addons:create graphenedb

  # To use Graph Story:
  heroku addons:create graphstory

.. seealso::

  GrapheneDB
    https://devcenter.heroku.com/articles/graphenedb
    For plans: https://addons.heroku.com/graphenedb

  Graph Story
    https://devcenter.heroku.com/articles/graphstory
    For plans: https://addons.heroku.com/graphstory
