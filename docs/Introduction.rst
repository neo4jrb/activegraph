Introduction
============

.. contents::
  :local:


Hi

Terminology
-----------

Neo4j
~~~~~

Node
  An `Object or Entity <http://en.wikipedia.org/wiki/Object_%28computer_science%29>`_ which has a distinct identity.  Can store arbitrary properties with values

Relationship
  A directed link from one node to another.  Can store arbitrary properties with values

Neo4j.rb
~~~~~~~~

Model
  A Ruby class including the `Neo4j::ActiveNode` module.  This module gives it the ability to define properties, validations, and callbacks

Association
  Defined on a **Model**.  Defines either a ``has_one`` or ``has_many`` relationship to a model.  A higher level abstraction of a **Relationship**

Installation
------------

Include in your ``Gemfile``:

.. code-block:: ruby

  # for rubygems
  gem 'neo4j', '~> 4.1.1'

If using Rails, include the railtie in ``application.rb``:

.. code-block:: ruby

  require 'neo4j/railtie'

To use the model generator, modify application.rb once more:

.. code-block:: ruby

  class Application < Rails::Application
    config.generators { |g| g.orm :neo4j }     
  end

If **not using Rails**, include the rake tasks in your Rakefile:

.. code-block:: ruby

  load 'neo4j/tasks/neo4j_server.rake'
  load 'neo4j/tasks/migration.rake'

If you don't already have a server you can install one with included rake tasks

Rake tasks and basic server connection are defined in the _neo4j-core gem: https://github.com/neo4jrb/neo4j-core. See its documentation (LINK TODO) for more details.

With the Rake tasks loaded, install Neo4j and start the server:

.. code-block:: unix

  rake neo4j:install[community-2.2.0]
  rake neo4j:start

(Note that if you are using zsh, you need to prefix any rake tasks with arguments with the noglob command, e.g. ``$ noglob bundle exec rake neo4j:install[community-2.2.0-M02]``.)

At this point, it will give you a message that the server has started or an error. Assuming everything is ok, point your browser to http://localhost:7474 and the Neo4j web console should load up.

Setup
-----

To open a session to the neo4j server database:

In Ruby
~~~~~~~~~

.. code-block:: ruby

  # In JRuby or MRI, using Neo4j Server mode. When the railtie is included, this happens automatically.
  Neo4j::Session.open(:server_db)

In JRuby
~~~~~~~~~~

On JRuby you can access the database in two different ways: using the embedded db or the server db.

Example, Open a session to the neo4j embedded database (running in the same JVM)

.. code-block:: ruby

  session = Neo4j::Session.open(:embedded_db, '/folder/db')
  session.start

In Rails
~~~~~~~~

Example of a rails ``config/application.rb`` file:

.. code-block:: ruby

  config.neo4j.session_options = { basic_auth: { username: 'foo', password: 'bar'} } 
  config.neo4j.session_type = :server_db 
  config.neo4j.session_path = 'http://localhost:7474'

For more configuration options, use the initialize session option parameter which is used to initialize a _Faraday: https://github.com/lostisland/faraday session.

Example:

.. code-block:: ruby

  config.neo4j.session_options = {initialize: { ssl: { verify: true }}

See https://gist.github.com/andreasronge/11189170 how to configure the Neo4j::Session with basic authentication from a non-rails application.

A ``_classname`` property is added to all nodes during creation to store the object's class name. This prevents an extra query to the database when wrapping the node in a Ruby class. To change the property name, add this to ``application.rb``:

.. code-block:: ruby

  config.neo4j[:class_name_property] = :new_name

.. note::

  The above is not true when using the master branch and Neo4j v2.1.5 or greater. See https://github.com/neo4jrb/neo4j/wiki/Neo4j.rb-v4-Introduction for more info.

Setup on Heroku
~~~~~~~~~~~~~~~

Add a Neo4j db to your application:

.. code-block:: unix

  # Substitute "chalk" with the plan of your choice
  heroku addons:add graphenedb:chalk

See https://devcenter.heroku.com/articles/graphenedb for more info, https://addons.heroku.com/graphenedb for plans.

Example of a rails ``config/application.rb`` file:

.. code-block:: ruby

  config.neo4j.session_type = :server_db 
  config.neo4j.session_path = ENV["GRAPHENEDB_URL"] || 'http://localhost:7474'

Setup in a new Rails app
~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: unix

  rails new myapp -m http://neo4jrb.io/neo4j/neo4j.rb -O
  cd myapp
  rake neo4j:install[community-2.1.6]
  rake neo4j:start

  rails generate scaffold User name:string email:string
  rails s
  open http://localhost:3000/users

Or manually modify the rails config file config/application.rb:

.. code-block:: ruby

  require 'neo4j/railtie'

  module Blog
    class Application < Rails::Application
       # To use generators:
       config.generators { |g| g.orm :neo4j }
       # This is for embedded db, only available from JRuby
       #config.neo4j.session_type = :embedded_db # or server_db
       #config.neo4j.session_path = File.expand_path('neo4j-db', Rails.root) # or http://localhost:port
    end
  end

You can skip Active Record by using the -O flag when generating the rails project.
