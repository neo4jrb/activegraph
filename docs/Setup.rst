Setup
===========

The neo4j.rb gems (``neo4j`` and ``neo4j-core``) support both Ruby and JRuby and can be used with many different frameworks and services.  If you're just looking to get started you'll probably want to use the ``neo4j`` gem which includes ``neo4j-core`` as a dependency.

Below are some instructions on how to get started:

Ruby on Rails
~~~~~~~~~~~~~

The following contains instructions on how to setup Neo4j with Rails.  If you prefer a video to follow along you can use `this YouTube video <https://www.youtube.com/watch?v=bDjbqRL9HcM>`_

There are two ways to add neo4j to your Rails project.  You can :ref:`generate a new project<generating-new-app>` with Neo4j as the default model mapper or you can :ref:`add it manually<add-gem-to-existing-project>`.

.. _generating-new-app:

Generating a new app
^^^^^^^^^^^^^^^^^^^^

To create a new Rails app with Neo4j as the default model mapper use ``-m`` to run a script from the Neo4j project and ``-O`` to exclude ActiveRecord like so:

.. code-block:: bash

  rails new myapp -m http://neo4jrb.io/neo4j/neo4j.rb -O

.. note::

  Due to network issues sometimes you may need to run this command two or three times for the file to download correctly

An example series of setup commands:

.. code-block:: bash

  rails new myapp -m http://neo4jrb.io/neo4j/neo4j.rb -O
  cd myapp
  rake neo4j:install[community-latest]
  rake neo4j:start

  rails generate scaffold User name:string email:string
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
  gem 'neo4j', '~> 9.0.0' # For example, see https://rubygems.org/gems/neo4j/versions for the latest versions

In ``application.rb``:

.. code-block:: ruby

  require 'neo4j/railtie'

.. note::

  Neo4j does not interfere with ActiveRecord and both can be used in the same application

If you want the ``rails generate`` command to generate Neo4j models by default you can modify ``application.rb`` like so:

.. code-block:: ruby

  class Application < Rails::Application
    # ...

    config.generators { |g| g.orm :neo4j }
  end

Rails configuration
^^^^^^^^^^^^^^^^^^^

For both new apps and existing apps there are multiple ways to configure how to connect to Neo4j.  You can use environment variables, the ``config/neo4j.yml`` file, or configure via the Rails application config.

For environment variables:

.. code-block:: bash

  NEO4J_URL=http://localhost:7474
  NEO4J_URL=http://user:pass@localhost:7474

  NEO4J_TYPE=bolt
  NEO4J_URL=bolt://user:pass@localhost:7687

  # jRuby only
  NEO4J_TYPE=embedded
  NEO4J_PATH=/path/to/graph.db

For the ``config/neo4j.yml`` file:

.. code-block:: yaml

  development:
    type: http
    url: http://localhost:7474

  test:
    type: http
    url: http://localhost:7575

  production:
    type: http
    url: http://neo4j:password@localhost:7000

The `railtie` provided by the `neo4j` gem will automatically look for and load this file.

You can also use your Rails configuration.  The following example can be put into ``config/application.rb`` or any of your environment configurations (``config/environments/(development|test|production).rb``) file:

.. code-block:: ruby

  config.neo4j.session.type = :http
  config.neo4j.session.url = 'http://localhost:7474'

  # Or, for Bolt

  config.neo4j.session.type = :bolt
  config.neo4j.session.url = 'bolt://localhost:7687'

  # Or, for embedded in jRuby

  config.neo4j.session.type = :embedded
  config.neo4j.session.path = '/path/to/graph.db'

Neo4j requires authentication by default but if you install using the built-in :doc:`rake tasks </RakeTasks>`) authentication is disabled.  If you are using authentication you can configure it like this:

.. code-block:: ruby

  config.neo4j.session.url = 'http://neo4j:password@localhost:7474'


Configuring Faraday
^^^^^^^^^^^^^^^^^^^

`Faraday <https://github.com/lostisland/faraday>`_ is used under the covers to connect to Neo4j.  You can use the ``initialize`` option to initialize the Faraday session.  Example:

.. code-block:: ruby

  # Before 8.0.x of `neo4j` gem
  config.neo4j.session.options = {initialize: { ssl: { verify: true }}}

  # After 8.0.x of `neo4j` gem
  # Switched to allowing a "configurator" since everything can be done there
  config.neo4j.session.options = {
    faraday_configurator: proc do |faraday|
      # The default configurator uses typhoeus (it was `Faraday::Adapter::NetHttpPersistent` for `neo4j-core` < 7.1.0), so if you override the configurator you must specify this
      faraday.adapter :typhoeus
      # Optionally you can instead specify another adaptor
      # faraday.use Faraday::Adapter::NetHttpPersistent

      # If you need to set options which would normally be the second argument of `Faraday.new`, you can do the following:
      faraday.options[:open_timeout] = 5
      faraday.options[:timeout] = 65
      faraday.options[:ssl] = { verify: true }
    end
  }

If you are just using the ``neo4j-core`` gem, the configurator can also be set via the Neo4j HTTP adaptor.  For example:

.. code-block:: ruby

  require 'neo4j/core/cypher_session/adaptors/http'
  faraday_configurator = proc do |faraday|
    faraday.adapter :typhoeus
  end
  http_adaptor = Neo4j::Core::CypherSession::Adaptors::HTTP.new('http://neo4j:pass@localhost:7474', faraday_configurator: faraday_configurator)

Any Ruby Project
~~~~~~~~~~~~~~~~

Include either ``neo4j`` or ``neo4j-core`` in your ``Gemfile`` (``neo4j`` includes ``neo4j-core`` as a dependency):

.. code-block:: ruby

  gem 'neo4j', '~> 9.0.0' # For example, see https://rubygems.org/gems/neo4j/versions for the latest versions
  # OR
  gem 'neo4j-core', '~> 8.0.0' # For example, see https://rubygems.org/gems/neo4j-core/versions for the latest versions

If using only ``neo4j-core`` you can optionally include the rake tasks (:doc:`documentation </RakeTasks>`) manually in your ``Rakefile``:

.. code-block:: ruby

  # Both are optional

  # To provide tasks to install/start/stop/configure Neo4j
  require 'neo4j/rake_tasks'
  # Comes from the `neo4j-rake_tasks` gem


  # It was formerly requried that you load migrations via a rake task like this:
  # load 'neo4j/tasks/migration.rake'
  # This is NO LONGER required.  Migrations are included automatically when requiring the `neo4j` gem.

If you don't already have a server you can install one with the rake tasks from ``neo4j_server.rake``.  See the (:doc:`rake tasks documentation </RakeTasks>`) for details on how to install, configure, and start/stop a Neo4j server in your project directory.

Connection
^^^^^^^^^^

To open a session to the neo4j server database:

In Ruby
```````

.. code-block:: ruby

  # In JRuby or MRI, using Neo4j Server mode. When the railtie is included, this happens automatically.
  Neo4j::Session.open(:http)

Embedded mode in JRuby
``````````````````````

In jRuby you can access the data in server mode as above.  If you want to run the database in "embedded" mode, however you can configure it like this:

.. code-block:: ruby

  neo4j_adaptor = Neo4j::Core::CypherSession::Adaptors::Embedded.new('/file/path/to/graph.db')
  neo4j_session = Neo4j::Core::CypherSession.new(neo4j_adaptor)

Embedded mode means that Neo4j is running inside your jRuby process.  This allows for direct access to the Neo4j Java APIs for faster and more direct querying.

Using the ``neo4j`` gem (``ActiveNode`` and ``ActiveRel``) without Rails
````````````````````````````````````````````````````````````````````````

To define your own session for the ``neo4j`` gem you create a ``Neo4j::Core::CypherSession`` object and establish it as the current session for the ``neo4j`` gem with the ``ActiveBase`` module (this is done automatically in Rails):

.. code-block:: ruby

  require 'neo4j/core/cypher_session/adaptors/http'
  neo4j_adaptor = Neo4j::Core::CypherSession::Adaptors::HTTP.new('http://user:pass@host:7474')
  Neo4j::ActiveBase.on_establish_session { Neo4j::Core::CypherSession.new(neo4j_adaptor) }

You could instead use the following, but ``on_establish_session`` will establish a new session for each thread for thread-safety and thus the above is recommended in general unless you know what you are doing:

.. code-block:: ruby

  Neo4j::ActiveBase.current_session = Neo4j::Core::CypherSession.new(neo4j_adaptor)

What if I'm integrating with a pre-existing Neo4j database?
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When trying to get the ``neo4j`` gem to integrate with a pre-existing Neo4j database instance (common in cases of migrating data from a legacy SQL database into a Neo4j-powered rails app), remember that every ``ActiveNode`` model is required to have an ID property with a ``unique`` constraint upon it, and that unique ID property will default to ``uuid`` unless you override it to use a different ID property.

This commonly leads to getting a ``Neo4j::DeprecatedSchemaDefinitionError`` in Rails when attempting to access a node populated into a Neo4j database directly via Cypher (i.e. when Rails didn't create the node itself). To solve or avoid this problem, be certain to define and constrain as unique a uuid property (or whatever other property you want Rails to treat as the unique ID property) in Cypher when loading the legacy data or use the methods discussed in :doc:`Unique IDs </UniqueIDs>`.

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

