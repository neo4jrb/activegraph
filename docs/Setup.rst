Setup
===========

The neo4j.rb gems (``neo4j`` and ``neo4j-core``) support both Ruby and JRuby and can be used with many different frameworks and services.  If you're just looking to get started you'll probably want to use the ``neo4j`` gem which includes ``neo4j-core`` as a dependency.

Below are some instructions on how to get started:

Ruby on Rails
~~~~~~~~~~~~~

The following contains instructions on how to setup Neo4j with Rails.  If you prefer a video to follow along you can use `this YouTube video <https://www.youtube.com/watch?v=bDjbqRL9HcM>`_

There are two ways to add neo4j to your Rails project.  You can LINK||generate a new project||LINK with Neo4j as the default model mapper or you can LINK||add it manually||LINK.

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

Adding the gem to an existing project
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Include in your ``Gemfile``:

.. code-block:: ruby

  # for rubygems
  gem 'neo4j', '~> 7.0.0'

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

For both new apps and existing apps the following configuration applies:

An example ``config/neo4j.yml`` file:

.. code-block:: yaml

  development:
    type: server_db
    url: http://localhost:7474

  test:
    type: server_db
    url: http://localhost:7575

  production:
    type: server_db
    url: http://neo4j:password@localhost:7000

The `railtie` provided by the `neo4j` gem will automatically look for and load this file.

You can also use your Rails configuration.  The following example can be put into ``config/application.rb`` or any of your environment configurations (``config/environments/(development|test|production).rb``) file:

.. code-block:: ruby

  config.neo4j.session_type = :server_db
  config.neo4j.session_path = 'http://localhost:7474'

Neo4j requires authentication by default but if you install using the built-in :doc:`rake tasks </RakeTasks>`) authentication is disabled.  If you are using authentication you can configure it like this:

.. code-block:: ruby

  config.neo4j.session_path = 'http://neo4j:password@localhost:7474'

Of course it's often the case that you don't want to expose your username / password / URL in your repository.  In these cases you can use the ``NEO4J_TYPE`` (either ``server_db`` or ``embedded_db``) and ``NEO4J_URL``/``NEO4J_PATH`` environment variables.

Configuring Faraday
^^^^^^^^^^^^^^^^^^^

`Faraday <https://github.com/lostisland/faraday>`_ is used under the covers to connect to Neo4j.  You can use the ``initialize`` option to initialize the Faraday session.  Example:

.. code-block:: ruby

  config.neo4j.session_options = {initialize: { ssl: { verify: true }}}

Any Ruby Project
~~~~~~~~~~~~~~~~

Include either ``neo4j`` or ``neo4j-core`` in your ``Gemfile`` (``neo4j`` includes ``neo4j-core`` as a dependency):

.. code-block:: ruby

  gem 'neo4j', '~> 7.0.0'
  # OR
  gem 'neo4j-core', '~> 7.0.0'

If using only ``neo4j-core`` you can optionally include the rake tasks (:doc:`documentation </RakeTasks>`) manually in your ``Rakefile``:

.. code-block:: ruby

  # Both are optional

  # This provides tasks to install/start/stop/configure Neo4j
  load 'neo4j/tasks/neo4j_server.rake'
  # This provides tasks to have migrations
  load 'neo4j/tasks/migration.rake'

If you don't already have a server you can install one with the rake tasks from ``neo4j_server.rake``.  See the (:doc:`rake tasks documentation </RakeTasks>`) for details on how to install, configure, and start/stop a Neo4j server in your project directory.

Connection
^^^^^^^^^^

To open a session to the neo4j server database:

In Ruby
```````

.. code-block:: ruby

  # In JRuby or MRI, using Neo4j Server mode. When the railtie is included, this happens automatically.
  Neo4j::Session.open(:server_db)

Embedded mode in JRuby
``````````````````````

In jRuby you can access the data in server mode as above.  If you want to run the database in "embedded" mode, however you can configure it like this:

.. code-block:: ruby

  session = Neo4j::Session.open(:embedded_db, '/folder/db')
  session.start

Embedded mode means that Neo4j is running inside your jRuby process.  This allows for direct access to the Neo4j Java APIs for faster and more direct querying.


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

Rails configuration
^^^^^^^^^^^^^^^^^^^

``config/application.rb``

.. code-block:: ruby

  config.neo4j.session_type = :server_db
  # GrapheneDB
  config.neo4j.session_path = ENV["GRAPHENEDB_URL"] || 'http://localhost:7474'
  # Graph Story
  config.neo4j.session_path = ENV["GRAPHSTORY_URL"] || 'http://localhost:7474'
