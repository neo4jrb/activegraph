Configuration
=============

To configure any of these variables you can do the following:

In Rails
~~~~~~~~

In either ``config/application.rb`` or one of the environment configurations (e.g. ``config/environments/development.rb``) you can set ``config.neo4j.variable_name = value`` where **variable_name** and **value** are as described below.

Other Ruby apps
~~~~~~~~~~~~~~~

You can set configuration variables directly in the Neo4j configuration class like so: ``ActiveGraph::Config[:variable_name] = value`` where **variable_name** and **value** are as described below.

.. _configuration-variables:

Variables
~~~~~~~~~

.. glossary::

  **association_model_namespace**
    **Default:** ``nil``

    Associations defined in node models will try to match association names to classes. For example, ``has_many :out, :student`` will look for a ``Student`` class. To avoid having to use ``model_class: 'MyModule::Student'``, this config option lets you specify the module that should be used globally for class name discovery.

    Of course, even with this option set, you can always override it by calling ``model_class: 'ClassName'``.

  **class_name_property**
    **Default:** ``:_classname``

    Which property should be used to determine the ``Node`` class to wrap the node in

    If there is no value for this property on a node the node`s labels will be used to determine the ``Node`` class

    .. seealso:: :ref:`activenode-wrapping`

  **enums_case_sensitive**
    **Default:** ``false``

    Determins whether enums property setters should be case sensitive or not.

    .. seealso:: :ref:`node-enums`

  **include_root_in_json**
    **Default:** ``true``

    When serializing ``Node`` and ``Relationship`` objects, should there be a root in the JSON of the model name.

    .. seealso:: http://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html

  **logger**
    **Default:** ``nil`` (or ``Rails.logger`` in Rails)

    A Ruby ``Logger`` object which is used to log Cypher queries (`info` level is used).  This is only for the ``neo4j`` gem (that is, for models created with the ``Node`` and ``Relationship`` modules).

  **module_handling**
    **Default:** ``:none``

    **Available values:** ``:demodulize``, ``:none``, ``proc``

    Determines what, if anything, should be done to module names when a model's class is set. By default, there is a direct mapping of an ``Node`` model name to the node label or an ``Relationship`` model to the relationship type, so `MyModule::MyClass` results in a label with the same name.

    The `:demodulize` option uses ActiveSupport's method of the same name to strip off modules. If you use a `proc`, it will the class name as an argument and you should return a string that modifies it as you see fit.

  **pretty_logged_cypher_queries**
    **Default:** ``nil``

    If true, format outputted queries with newlines and colors to be more easily readable by humans

  **record_timestamps**
    **Default:** ``false``

    A Rails-inspired configuration to manage inclusion of the Timestamps module. If set to true, all Node and Relationship models will include the Timestamps module and have ``:created_at`` and ``:updated_at`` properties.

  **skip_migration_check**
    **Default:** ``false``

    Prevents the ``neo4j`` gem from raising ``ActiveGraph::PendingMigrationError`` in web requests when migrations haven't been run.  For environments (like testing) where you need to use the ``neo4j:schema:load`` rake task to build the database instead of migrations.  Automatically set to ``true`` in Rails test environments by default

  .. _configuration-class_name_property:

  **timestamp_type**
    **Default:** ``DateTime``

    This method returns the specified default type for the ``:created_at`` and ``:updated_at`` timestamps. You can also specify another type (e.g. ``Integer``).

  **transform_rel_type**
    **Default:** ``:upcase``

    **Available values:** ``:upcase``, ``:downcase``, ``:legacy``, ``:none``

    Determines how relationship types for ``Relationship`` models are transformed when stored in the database.  By default this is upper-case to match with Neo4j convention so if you specify an ``Relationship`` model of ``HasPost`` then the relationship type in the database will be ``HAS_POST``

    ``:legacy``
      Causes the type to be downcased and preceded by a `#`
    ``:none``
      Uses the type as specified

  **wait_for_connection**
    **Default:** ``false``

    This allows you to tell the gem to wait for up to 60 seconds for Neo4j to be available.  This is useful in environments such as Docker Compose.  This is currently only for Rails

  **verbose_query_logs**
    **Default:** ``false``

    Specifies that queries outputted to the log also get a source file / line outputted to aid debugging.

Instrumented events
~~~~~~~~~~~~~~~~~~~

The ``activegraph`` gem instruments a handful of events so that users can subscribe to them to do logging, metrics, or anything else that they need.  For example, to create a block which is called any time a query is made via the gem:

.. code-block:: ruby

  ActiveGraph::Base.subscribe_to_query do |message|
    puts message
  end

The argument to the block (``message`` in this case) will be an ANSI formatted string which can be outputted or stored.  If you want to access this event at a lower level, ``subscribe_to_query`` is actually tied to the ``neo4j.core.cypher_query`` event to which you could subscribe to like:

.. code-block:: ruby

  ActiveSupport::Notifications.subscribe('neo4j.core.cypher_query') do |name, start, finish, id, payload|
    puts payload[:query].to_cypher
    # or
    payload[:query].print_cypher

    puts "Query took: #{(finish - start)} seconds"
  end

All methods and their corresponding events:

  **ActiveGraph::Base.subscribe_to_query**
    **neo4j.core.cypher_query**

  **ActiveGraph::Base.subscribe_to_request**
    **neo4j.core.http.request**

