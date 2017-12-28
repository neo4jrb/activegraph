ActiveLabel
===========

As you build out your application's models, you likely will want to share code between them.
Neo4jrb's ``ActiveNode`` module supports class inheritance, allowing you to create "submodels" which 
inherit the methods and labels of their ``ActiveNode`` parents while also adding their own submodel specific
label & methods. This code sharing strategy should be familiar to anyone coming from the ActiveRecord world.

Sometime's however, inheritance is not always appropriate. Sometimes what you want to do is conditionally add 
a module of functionality to an ActiveNode model, but only if a specific label is present on the node. 
For an example of when this is needed, look at the Neo4j's example movie database (https://neo4j.com/developer/movie-database/). 
In this example, a Person node is sometimes an Actor, sometimes a Director, sometimes a User, and sometimes a 
combination of Actor, Director, and/or User.

Multiple inheritance such as this is not possible with ``ActiveNode`` (or with ActiveRecord). This
is where ``ActiveLabel`` comes to the rescue! ``ActiveLabel`` allows you to create a Ruby module which is only
applied to an ``ActiveNode`` model when a specific label is attached to an instance of the model. Using our
example movie database from above, you could create an ``ActiveLabel`` module which only adds Actor methods and
properties to an instance of Person if a Person node also has an Actor label. Or only adds InShowbusiness methods
and properties to an instance of Person if a Person node has `either` Actor or Director labels.

``ActiveLabel`` can fully replace ``ActiveNode`` inheritence, but it involves a different way of thinking
then what many ActiveRecord developers might be used to. If you're just starting out with Neo4jrb, you might find
it easiest to stick with the "ActiveRecord" like workflow provided by ``ActiveNode`` and inheritence.
But as you get more comfortable with Neo4j's flexibility and 
polymorphism, you'll might find that ``ActiveLabel`` is the better option for many tasks.

.. code-block:: ruby

  class Person
    include Neo4j::ActiveNode
    include Actor
    include Director
    include User

    property :name, type: String
  end

  class Movie
    include Neo4j::ActiveNode

    property :name, type: String
  end

.. code-block:: ruby

  module Actor
    include Neo4j::ActiveLabel
    include InShowbusiness

    has_many :out, :acts_in, type: :ACTS_IN, model_class: :Movie
  end

  module Director
    include Neo4j::ActiveLabel
    include InShowbusiness

    has_many :out, :directed, type: :DIRECTED, model_class: :Movie
  end

  module InShowbusiness
    include Neo4j::ActiveLabel

    self.associated_labels = [:Actor, :Director]
    self.associated_labels_matcher = :any

    property :biography
    property :lastModified
    property :version
  end

  module User
    include Neo4j::ActiveLabel

    property :login
    property :password
    property :roles

    module InstanceMethods
      def administrate_stuff
        puts "administrate stuff"
      end
    end
  end


Creating
--------

``ActiveLabel`` modules are defined by creating a standard ruby module with ``include Neo4j::ActiveLabel``.
By convention, the ``ActiveLabel`` module will be associated with a label equal to the module name. For example,
in the example above, the ``Actor`` ``ActiveLabel`` module is associated with the ``:Actor`` label. You can 
customize the label(s) which an ``ActiveLabel`` module is associated with using ``self.associated_labels =``. You must also
include an ``ActiveLabel`` module in an ``ActiveNode`` class if you want the class to respond to the ``ActiveLabel``.

``ActiveLabel`` modules have several parts:

.. code-block:: ruby

  module Actor
    include Neo4j::ActiveLabel # adds ActiveLabel functionality to the Actor module

    # ``ActiveLabel`` modules can have associations and properties just like ``ActiveNode`` classes
    property :popularity
    has_one :out, :friend, type: :FRIEND, model_class: :Person

    included do
      # When a node is retrieved from the database, it is mapped to an ``ActiveNode`` class and a new
      # instance of that class is created. We'll call this created object obj A.
      # If obj A's class includes this ``ActiveLabel``, and, additionally, obj A has the label associated
      # with this ``ActiveLabel``, then this included block will be evaluated
      # within the context of obj A.
    end

    module InstanceMethods
      # After obj A has been found and initialized, before the included block is evaluated, obj A will
      # be extended with these InstanceMethods (e.g. obj.extend(InstanceMethods))

      def act
        puts "I acted!"
      end
    end

    module ClassMethods
      # Similar to ``ActiveSupport::Concern``, when this ``ActiveLabel`` module is included in an
      # ``ActiveNode`` class, the class will be extended with these singleton methods (e.g. Person.extend(ClassMethods))

      def actor_popularity_scale
        puts "5 stars = excellent. 1 star = poor."
      end
    end
  end

``ActiveLabel`` modules only describe functionality that is tied to a label. Actually adding that label to instances of a class
is a seperate step. If you'd like to add a label to specific instances of a class, you can use standard ``neo4j-core`` methods
``add_label()`` or ``remove_label``. You can also use special helper methods that ``ActiveLabel`` adds to a class when it is
included in a class

.. code-block:: ruby

  # Initializes a Person with additional Actor label
  Person.actor.new

  # Creates a Person with additional Actor label
  Person.actor.create

  # Creates a Person with additional Actor AND Director labels
  Person.actor.director.create

If you'd like to `always` add one or more additional labels to instances of a class, you can use the ``ActiveNode`` ``label`` method

.. code-block:: ruby

  class Person
    include Neo4j::ActiveNode
    include Actor
    include Director
    include User

    # ``label :Actor, optional: true`` automatically adds the label ``:Actor``
    # to every instance of the Person class. The :Actor label is technically
    # optional, even though it is always added, because a node will still be mapped
    # to the Person class even if you manually remove the :Actor label from it.
    label :Actor, optional: true

    # If you call the ``label`` method without the ``optional: true`` argument,
    # then nodes will only be mapped to the Person class if the label is
    # also present on the node. (i.e. removing the :User label from a node will
    # mean that that node is no longer considered a Person)
    label :User
  end


Including an ``ActiveLabel`` module in a class will `automatically` add a few helper methods to the class and class instances.
For example, using the ``Actor`` ``ActiveLabel`` module:

1. You can call ``person.actor?`` which will return true if the obj has the label associated with the ``Actor`` ``ActiveLabel``.
2. You can call ``Person.actor.new`` or ``Person.actor.create`` to initialize / create a new ``Person`` instance with the additional ``Actor`` label.
3. You can call ``Person.actor.all`` or ``Person.actor.first`` to return all ``Person`` nodes with the ``Actor`` label. In fact, calling ``Person.actor`` simply adds a label scope, which can be combined with any custom scopes you have (e.g. ``Person.most_popular`` -> ``Person.actor.most_popular``)

To dry up your code, you can include ``ActiveLabel B`` inside ``ActiveLabel A``. This ensures that when you include
``ActiveLabel A`` in a module you also always include ``Activelabel B``

.. code-block:: ruby

  module Hollywood
    include Neo4j::ActiveLabel

    self.associated_labels = [:Actor, :Director]
    self.associated_labels_matcher = :any

    property :name
  end

  module Actor
    include Neo4j::ActiveLabel
    include Hollywood
  end

  module Director
    include Neo4j::ActiveLabel
    include Hollywood
  end

Querying
--------

Querying for ``ActiveLabel``s is easy, and can allow you to query across classes.

.. code-block:: ruby

  # This returns all nodes which have the Actor label
  Actor.all

  # This returns all nodes with the Director label which have a directed association to
  # a node with the title "Star Wars"
  # This works because the ``Director`` ``ActiveLabel`` defines a ``directed`` association
  Director.as(:dir).directed.where(title: 'Star Wars').pluck('DISTINCT dir')

Including an ``ActiveLabel`` module in a class will `automatically` add a few helper methods to the class and class instances.

.. code-block:: ruby

  Person.actor.all

  Person.actor.first

Calling ``Person.actor`` simply adds a label scope, which can be combined with any custom scopes you have (e.g.
``Person.most_popular`` -> ``Person.actor.most_popular``

Associations
~~~~~~~~~~~~

You can create associations with ActiveLabels:

.. code-block:: ruby

  class Movie
    include Neo4j::ActiveNode

    has_many :in, :actors, type: :ACTS_IN, label_module: :Actor

    # `label_module` acts as a filter to the `model_class` argument.
    # Both `model_class` and `label_module` can be arrays
    has_many :in, :human_actors, type: :ACTS_IN, label_module: :Actor, model_class: :Person
  end

If you want more control over your association, you can use the ``node_labels:`` option instead

.. code-block:: ruby

  class Movie
    include Neo4j::ActiveNode

    # The node_labels option accepts a two dimentional array. Each array in the node_labels
    # array includes a set of labels that the association will match against. In the example
    # below, the ``actors`` association only includes nodes which have either ``:Actor:Person``
    # OR ``:Actor:Animal`` labels and have an ``<-[:ACTS_IN]-`` relation to a ``Movie`` node
    has_many :in, :actors, type: :ACTS_IN, node_labels: [[:Actor, :Person], [:Actor, :Animal]]

    # Other valid params for the node_labels option are
    has_many :in, :actors, type: :ACTS_IN, node_labels: [[:Actor, :Person], :Actor]

    # or
    has_many :in, :actors, type: :ACTS_IN, node_labels: :Actor
  end

Note, while the ``label_module`` option requires its params to resolve to ``ActiveLabel`` modules, the ``node_labels``
option doesn't. The ``node_labels`` option simply matches against the specified labels.

Multiple Conditions
-------------------

Sometimes you may wish for ``ActiveLabel`` code to be associated with an array of labels, rather than a single label.
Perhaps the code triggers if `any` label in the array is present, or perhaps it only triggers if `all` labels in the
array are present.

.. code-block:: ruby

  module Hollywood
    include Neo4j::ActiveLabel

    self.associated_labels = [:Actor, :Director]
    self.associated_labels_matcher = :any

    # OR

    self.associated_labels = [:Actor, :Director]
    self.associated_labels_matcher = :all
    
  end

By default, ``self.associated_labels_matcher == :any``

included_if block
~~~~~~~~~~~~~~~~~

Sometimes conditional functionality is limited to one class, and is simple enough that a full ``ActiveLabel`` module seems like
overkill. You can make use of ``included_if_any`` and ``included_if_all`` methods to specify blocks of code that only
run if `any` or `all` of the specified labels are present on a node.

.. code-block:: ruby

  class Person
    include Neo4j::ActiveLabel

    # only run if a Person node also has the Actor or Director labels
    included_if_any :Actor, :Director do
      property :medium_ego
    end

    # only run if a Person node also has the Actor AND Director labels
    included_if_all :Actor, :Director do
      property :large_ego
    end
  end
