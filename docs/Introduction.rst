Introduction
============

.. contents::
  :local:


Neo4j.rb is an ActiveRecord-inspired OGM (Object Graph Mapping, like `ORM <http://en.wikipedia.org/wiki/Object-relational_mapping>`_) for Ruby supporting Neo4j 2.1+.

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

Neo4j.rb consists of the `neo4j` and `neo4j-core` gems.

Model
  A Ruby class including either the `Neo4j::ActiveNode` module or the `Neo4j::ActiveRel` module from the `neo4j` gem.  These modules give classes the ability to define properties, associations, validations, and callbacks

Association
  Defined on a **Model**.  Defines either a ``has_one`` or ``has_many`` relationship to a model.  A higher level abstraction of a **Relationship**

Code Examples
-------------

With Neo4j.rb, you can use either high-level abstractions for convenience or low level APIs for flexibility.

ActiveNode
~~~~~~~~~~

ActiveNode provides an Object Graph Model (OGM) for abstracting Neo4j concepts with an ``ActiveRecord``-like API:

.. code-block:: ruby

  # Models to create nodes
  person = Person.create(name: 'James', age: 15)

  # Get object by attributes
  person = Person.find_by(name: 'James', age: 15)

  # Associations to traverse relationships
  person.houses.map(&:address)

  # Method-chaining to build and execute queries
  Person.where(name: 'James').order(age: :desc).first

  # Query building methods can be chained with associations
  # Here we get other owners for pre-2005 vehicles owned by the person in question
  person.vehicles(:v).where('v.year < 2005').owners(:other).to_a

Installation
------------

The following contains instructions on how to setup Neo4j with Rails.  If you prefer a video to follow along with you can view `this YouTube video <https://www.youtube.com/watch?v=bDjbqRL9HcM>`_

Rails
~~~~~

There are two ways to add neo4j to your Rails project.  You can generate a new project with Neo4j as the default model mapper or you can add it manually.

Generating a new app
^^^^^^^^^^^^^^^^^^^^

You can create a new Rails app with the `-m` and `-O` options like so to default to using Neo4j:

.. code-block:: unix

  rails new myapp -m http://neo4jrb.io/neo4j/neo4j.rb -O

.. note::

  You may need to run this command two or three times for the file to download correctly

An example series of setup commands:

.. code-block:: unix

  rails new myapp -m http://neo4jrb.io/neo4j/neo4j.rb -O
  cd myapp
  rake neo4j:install[community-2.2.2]
  rake neo4j:start

  rails generate scaffold User name:string email:string
  rails s
  open http://localhost:3000/users


Adding the gem to your project
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Include in your ``Gemfile``:

.. code-block:: ruby

  # for rubygems
  gem 'neo4j', '~> 5.0.0'

In ``application.rb``:

.. code-block:: ruby

  require 'neo4j/railtie'

To use the model generator, modify application.rb:

.. code-block:: ruby

  class Application < Rails::Application
    config.generators { |g| g.orm :neo4j }
  end

Outside Rails
~~~~~~~~~~~~~

Include the gem's :doc:`rake tasks </RakeTasks>` in your Rakefile:

.. code-block:: ruby

  load 'neo4j/tasks/neo4j_server.rake'
  load 'neo4j/tasks/migration.rake'

If you don't already have a server you can install one with included rake tasks

Rake tasks and basic server connection are defined in the _neo4j-core gem: https://github.com/neo4jrb/neo4j-core. See `its documentation </RakeTasks>` for more details.

With the Rake tasks loaded, install Neo4j and start the server:

.. code-block:: unix

  rake neo4j:install[community-2.2.0]
  rake neo4j:start

(Note that if you are using zsh, you need to prefix any rake tasks with arguments with the noglob command, e.g. ``$ noglob bundle exec rake neo4j:install[community-2.2.0-M02]``.)

At this point, it will give you a message that the server has started or an error. Assuming everything is ok, point your browser to http://localhost:7474 and the Neo4j web console should load up.

Connection
----------

To open a session to the neo4j server database:

In Ruby
~~~~~~~~~

.. code-block:: ruby

  # In JRuby or MRI, using Neo4j Server mode. When the railtie is included, this happens automatically.
  Neo4j::Session.open(:server_db)

In JRuby
~~~~~~~~

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

On Heroku
~~~~~~~~~

Add a Neo4j db to your application:

.. code-block:: unix

  # Substitute "chalk" with the plan of your choice
  heroku addons:add graphenedb:chalk

See https://devcenter.heroku.com/articles/graphenedb for more info, https://addons.heroku.com/graphenedb for plans.

Example of a rails ``config/application.rb`` file:

.. code-block:: ruby

  config.neo4j.session_type = :server_db
  config.neo4j.session_path = ENV["GRAPHENEDB_URL"] || 'http://localhost:7474'

