Node
==========

Node is the ActiveRecord replacement module for Rails. Its syntax should be familiar for ActiveRecord users but has some unique qualities.

To use Node, include ActiveGraph::Node in a class.

.. code-block:: ruby

    class Post
      include ActiveGraph::Node
    end

Properties
----------

Properties for ActiveGraph::Node objects must be declared by default. Properties are declared using the property method which is the same as attribute from the active_attr gem.

Example:

.. code-block:: ruby

    class Post
      include ActiveGraph::Node
      property :title
      property :text, default: 'bla bla bla'
      property :score, type: Integer, default: 0

      validates :title, :presence => true
      validates :score, numericality: { only_integer: true }

      before_save do
        self.score = score * 100
      end

      has_n :friends
    end

See the Properties section for additional information.


.. seealso::
  .. raw:: html

    There is also a screencast available reviewing properties:

    <iframe width="560" height="315" src="https://www.youtube.com/embed/2pCSQkHkPC8" frameborder="0" allowfullscreen></iframe>

Labels
~~~~~~

By default ``Node`` takes your model class' name and uses it directly as the Neo4j label for the nodes it represents.  This even includes using the module namespace of the class.  That is, the class  ``MyClass`` in the ``MyModule`` module will have the label ``MyModule::MyClass``.  To change this behavior, see the :term:`module_handling` configuration variable.

Additionally you can change the name of a particular ``Node`` by using ``mapped_label_name`` like so:

.. code-block:: ruby

    class Post
      include ActiveGraph::Node

      self.mapped_label_name = 'BlogPost'
    end

Indexes and Constraints
~~~~~~~~~~~~~~~~~~~~~~~

To declare a index on a constraint on a property, you should create a migration.  See :doc:`Migrations`

.. note::

  In previous versions of ``Node`` indexes and constraints were defined on properties directly on the models and were automatically created.  This turned out to be not safe, and migrations are now required to create indexes and migrations.

Labels
~~~~~~

The class name maps directly to the label.  In the following case both the class name and label are ``Post``

.. code-block:: ruby

    class Post
      include ActiveGraph::Node
    end

If you want to specify a different label for your class you can use ``mapped_label_name``:

.. code-block:: ruby

    class Post
      include ActiveGraph::Node

      self.mapped_label_name = 'BlogPost'
    end

If you would like to use multiple labels you can use class inheritance.  In the following case object created with the `Article` model would have both `Post` and `Article` labels.  When querying `Article` both labels are required on the nodes as well.

.. code-block:: ruby

    class Post
      include ActiveGraph::Node
    end

    class Article < Post
    end



Serialization
~~~~~~~~~~~~~

Pass a property name as a symbol to the serialize method if you want to save JSON serializable data (strings, numbers, hash, array,  array with mixed object types*, etc.) to the database.

.. code-block:: ruby

    class Student
      include ActiveGraph::Node

      property :links

      serialize :links
    end

    s = Student.create(links: { neo4j: 'http://www.neo4j.org', neotech: 'http://www.neotechnology.com' })
    s.links
    # => {"neo4j"=>"http://www.neo4j.org", "neotech"=>"http://www.neotechnology.com"}
    s.links.class
    # => Hash

Neo4j.rb serializes as JSON by default but pass it the constant Hash as a second parameter to serialize as YAML. Those coming from ActiveRecord will recognize this behavior, though Rails serializes as YAML by default.

*Neo4j allows you to save Ruby arrays to undefined or String types but their contents need to all be of the same type. You can do user.stuff = [1, 2, 3] or user.stuff = ["beer, "pizza", "doritos"] but not user.stuff = [1, "beer", "pizza"]. If you wanted to do that, you could call serialize on your property in the model.*

.. _node-enums:

Enums
~~~~~~
You can declare special properties that maps an integer value in the database with a set of keywords, like ``ActiveRecord::Enum``

.. code-block:: ruby

    class Media
      include ActiveGraph::Node

      enum type: [:image, :video, :unknown]
    end

    media = Media.create(type: :video)
    media.type
    # => :video
    media.image!
    media.image?
    # => true

For every keyword specified, a couple of methods are defined to set or check the current enum state (In the example: `image?`, `image!`, `video?`, ... ).

With options ``_prefix`` and ``_suffix``, you can define how this methods are generating, by adding a prefix or a suffix.

With ``_prefix: :something``, something will be added before every method name.

.. code-block:: ruby

    Media.enum type: [:image, :video, :unknown], _prefix: :something
    media.something_image?
    media.something_image!

With ``_suffix: true``, instead, the name of the enum is added in the bottom of all methods:

.. code-block:: ruby

    Media.enum type: [:image, :video, :unknown], _suffix: true
    media.image_type?
    media.image_type!

You can find elements by enum value by using a set of scope that ``enum`` defines:

.. code-block:: ruby

    Media.image
    # => CYPHER: "MATCH (result_media:`Media`) WHERE (result_media.type = 0)"
    Media.video
    # => CYPHER: "MATCH (result_media:`Media`) WHERE (result_media.type = 1)"

Or by using ``where``:

.. code-block:: ruby

    Media.where(type: :image)
    # => CYPHER: "MATCH (result_media:`Media`) WHERE (result_media.type = 0)"
    Media.where(type: [Media.types[:image], Media.types[:video]])
    # => CYPHER: "MATCH (result_media:`StoredFile`) WHERE (result_media.type IN [0, 1])"
    Media.as(:m).where('m.type <> ?', Media.types[:image])
    # => CYPHER: "MATCH (result_media:`StoredFile`) WHERE (result_media.type <> 0)"

By default, every ``enum`` property will require you to add an associated index to improve query performance. If you want to disable this, simply pass ``_index: false`` to ``enum``:

.. code-block:: ruby

    class Media
      include ActiveGraph::Node

      enum type: [:image, :video, :unknown], _index: false
    end

Sometimes it is desirable to have a default value for an ``enum`` property.  To acheive this, you can simply pass the ``_default`` option when defining the enum:

.. code-block:: ruby

    class Media
      include ActiveGraph::Node

      enum type: [:image, :video, :unknown], _default: :video
    end

By default, enum setters are `case insensitive` (in the example below, ``Media.create(type: 'VIDEO').type == :video``). If you wish to disable this for a specific enum, pass the ``_case_sensitive: true`` option. if you wish to change the global default for ``_case_sensitive`` to ``true``, use Neo4jrb's ``enums_case_sensitive`` config option (detailed in the :ref:`configuration-variables` section).

.. code-block:: ruby

    class Media
      include ActiveGraph::Node

      enum type: [:image, :video, :unknown], _case_sensitive: false
    end

.. _activenode-scopes:

Scopes
------

Scopes in ``Node`` are a way of defining a subset of nodes for a particular ``Node`` model.  This could be as simple as:


.. code-block:: ruby

    class Person
      include ActiveGraph::Node

      scope :minors, -> { where(age: 0..17) }
    end

This allows you chain a description of the defined set of nodes which can make your code easier to read such as ``Person.minors`` or ``Car.all.owners.minors``.  While scopes are very useful in encapsulating logic, this scope doesn't neccessarily save us much beyond simply using ``Person.where(age: 0..17)`` directly.  Scopes become much more useful when they encapsulate more complicated logic:

.. code-block:: ruby

    class Person
      include ActiveGraph::Node

      scope :eligible, -> { where_not(age: 0..17).where(completed_form: true) }
    end

And because you can chain scopes together, this can make your query chains very composable and expressive like:

.. code-block:: ruby

    # Getting all hybrid convertables owned by recently active eligible people
    Person.eligible.where(recently_active: true).cars.hybrids.convertables

While that's useful in of itself, sometimes you want to be able to create more dynamic scopes by passing arguments.  This is supported like so:

.. code-block:: ruby

    class Person
      include ActiveGraph::Node

      scope :around_age_of, -> (age) { where(age: (age - 5..age + 5)) }
    end

    # Which can be used as:
    Person.around_age_of(20)
    # or
    Car.all.owners.around_age_of(20)

All of the examples so far have used the Ruby API for automatically generating Cypher.  While it is often possible to get by with this, it is sometimes not possible to create a scope without defining it with a Cypher string.  For example, if you need to use ``OR``:

.. code-block:: ruby

    class Person
      include ActiveGraph::Node

      scope :non_teenagers, -> { where("#{identity}.age < 13 OR #{identity}.age >= 18") }
    end


Since a Cypher query can have a number of different nodes and relationships that it is referencing, we need to be able to refer to the current node's variable.  This is why we call the ``identity`` method, which will give the variable which is being used in the query chain on which the scope is being called.

.. warning::

  Since the ``identity`` comes from whatever was specified as the cypher variable for the node on the other side of the association.  If the cypher variables were generated from an untrusted source (like from a user of your app) you may leave yourself open to a Cypher injection vulnerability.  It is not recommended to generate your Cypher variables based on user input!

Finally, the ``scope`` method just gives us a convenient way of having a method on our model class which returns another query chain object.  Sometimes to make even more complex logic or even to just return a simple result which can be called on a query chain but which doesn't continue the chain, we can create a class method ourselves:

.. code-block:: ruby

    class Person
      include ActiveGraph::Node

      def self.average_age
        all(:person).pluck('avg(person.age)').first
      end
    end

So if you wanted to find the average age of all eligible people, you could call ``Person.eligible.average_age`` and you would be given a single number.

To implement a more complicated scope with a class method you simply need to return a query chain at the end.

.. _activenode-wrapping:

Wrapping
--------

When loading a node from the database there is a process to determine which ``Node`` model to choose for wrapping the node.  If nothing is configured on your part then when a node is created labels will be saved representing all of the classes in the hierarchy.

That is, if you have a ``Teacher`` class inheriting from a ``Person`` model, then creating a ``Person`` object will create a node in the database with a ``Person`` label, but creating a ``Teacher`` object will create a node with both the ``Teacher`` and ``Person`` labels.

If there is a value for the property defined by :term:`class_name_property` then the value of that property will be used directly to determine the class to wrap the node in.


Callbacks
---------

Implements like Active Records the following callback hooks:

* initialize
* validation
* find
* save
* create
* update
* destroy

created_at, updated_at
----------------------

.. code-block:: ruby

    class Blog
      include ActiveGraph::Node

      include ActiveGraph::Timestamps # will give model created_at and updated_at timestamps
      include ActiveGraph::Timestamps::Created # will give model created_at timestamp
      include ActiveGraph::Timestamps::Updated # will give model updated_at timestamp
    end

Validation
----------

Support the Active Model validation, such as:

validates :age, presence: true
validates_uniqueness_of :name, :scope => :adult

id property (primary key)
-------------------------

Unique IDs are automatically created for all nodes using SecureRandom::uuid. See :doc:`UniqueIDs </Setup>` for details.

Associations
------------

``has_many`` and ``has_one`` associations can also be defined on ``Node`` models to make querying and creating relationships easier.

.. code-block:: ruby

    class Post
      include ActiveGraph::Node
      has_many :in, :comments, origin: :post
      has_one :out, :author, type: :author, model_class: :Person
    end

    class Comment
      include ActiveGraph::Node
      has_one :out, :post, type: :post
      has_one :out, :author, type: :author, model_class: :Person
    end

    class Person
      include ActiveGraph::Node
      has_many :in, :posts, origin: :author
      has_many :in, :comments, origin: :author

      # Match all incoming relationship types
      has_many :in, :written_things, type: false, model_class: [:Post, :Comment]

      # or if you want to match all model classes:
      # has_many :in, :written_things, type: false, model_class: false

      # or if you watch to match Posts and Comments on all relationships (in and out)
      # has_many :both, :written_things, type: false, model_class: [:Post, :Comment]
    end

You can query associations:

.. code-block:: ruby

    post.comments.to_a          # Array of comments
    comment.post                # Post object
    comment.post.comments       # Original comment and all of it's siblings.  Makes just one query
    post.comments.author.posts # All posts of people who have commented on the post.  Still makes just one query

When querying ``has_one`` associations, by default ``.first`` will be called on the result. This makes the result non-chainable if the result is ``nil``. If you want to ensure a chainable result, you can call ``has_one`` with a ``chainable: true`` argument.

.. code-block:: ruby

    comment.post                    # Post object
    comment.post(chainable: true)   # Association proxy object wrapping post

You can create associations

.. code-block:: ruby

    post.comments = [comment1, comment2]  # Removes all existing relationships
    post.comments << comment3             # Creates new relationship

    comment.post = post1                  # Removes all existing relationships

Updating Associations
~~~~~~~~~~~~~~~~~~~~~

You can update attributes for objects of an association like this:

.. code-block:: ruby

    post.comments.update_all(flagged: true)
    post.comments.where(text: /.*cats.*/).update_all(flagged: true)

You can even update properties of the relationships for the associations like so:

.. code-block:: ruby

    post.comments.update_all_rels(flagged: true)
    post.comments.where(text: /.*cats.*/).update_all_rels(flagged: true)
    # Or to filter on the relationships
    post.comments.where(flagged: nil).update_all_rels(flagged: true)

Polymorphic Associations
~~~~~~~~~~~~~~~~~~~~~~~~

``has_one`` or ``has_many`` associations which target multiple ``model_class`` are called polymorphic associations.
This is done by setting ``model_class: false`` or ``model_class: [:ModelOne, :ModelTwo, :Etc]``. In our example, the ``Person`` class has a polymorphic association ``written_things``

.. code-block:: ruby

    class Person
      include ActiveGraph::Node

      # Match all incoming relationship types
      has_many :in, :written_things, type: :WROTE, model_class: [:Post, :Comment]
    end

You can't perform standard association chains on a polymorphic association. For example, while you `can` call ``post.comments.author.written_things``, you `cannot` call
``post.comments.author.written_things.post.comments`` (an exception will be raised). In this example, the return of ``.written_things`` can be either a ``Post`` object or a ``Comment`` object, any method you called
on an association made up of them both could have a different meaning for the ``Post`` object vs the ``Comment`` object. So how can you execute ``post.comments.author.written_things.post.comments``?
This is where ``.query_as`` and ``.proxy_as`` come to the rescue! While ``Node`` doesn't know how to handle the ``.post`` call on ``.written_things``,
you `know` that the path from the return of ``.written_things`` to ``Post`` nodes is ``(written_thing)-[:post]->(post:Post)``. To help ``Node`` out, convert the `AssociationProxy`` object returned by ``post.comments.author.written_things`` into a ``Query`` object with ``.query_as()``, then manually specify the path of ``.post``. Like so:

.. code-block:: ruby

    post.comments.author.written_things.query_as(:written_thing).match("(written_thing)-[:post]->(post:Post)")

It's worth noting that the object returned by this chain is now a ``Query`` object, meaning that if you wish to get the result (``(post:Post)``), you'll need to ``.pluck(:post)`` it.
However, we don't want to get the result yet. Instead, we wish to perform further queries. Because the end of the chain is now a ``Query``, we could continue
to manually describe the path to the nodes we want using the ``Query`` API of ``.match``, ``.where``, ``.return``, etc.
For example, to get ``post.comments.author.written_things.post.comments`` we could

.. code-block:: ruby

    post.comments.author.written_things.query_as(:written_thing).match("(written_thing)-[:post]->(post:Post)").match("(post)<-[:post]-(comment:Comment)").pluck(:comment)

But this isn't ideal. It would be nice to make use of ``Node``'s association chains to complete our query. We `know` that the return of ``post.comments.author.written_things.query_as(:written_thing).match("(written_thing)-[:post]->(post:Post)")``
is a ``Post`` object, after all. To allow for association chains in this circumstance, ``.proxy_as()`` comes to the rescue! If we `know` that a ``Query`` will return a specific model class,
``proxy_as`` allows us to tell Neo4jrb this, and begin association chaining from that point. For example

.. code-block:: ruby

    post.comments.author.written_things.query_as(:written_thing).match("(written_thing)-[:post]->(post:Post)").proxy_as(Post, :post).comments.author

.. seealso::

    #query_as http://www.rubydoc.info/gems/activegraph/ActiveGraph/Node/Query/QueryProxy#query_as-instance_method
    and
    #proxy_as http://www.rubydoc.info/gems/activegraph/ActiveGraph/Core/Query#proxy_as-instance_method

Dependent Associations
~~~~~~~~~~~~~~~~~~~~~~

Similar to ActiveRecord, you can specify four ``dependent`` options when declaring an association.

.. code-block:: ruby

    class Route
      include ActiveGraph::Node
      has_many :out, :stops, type: :STOPPING_AT, dependent: :delete_orphans
    end

The available options are:

* ``:delete``, which will delete all associated records in Cypher. Callbacks will not be called. This is the fastest method.
* ``:destroy``, which will call ``each`` on the association and then ``destroy`` on each related object. Callbacks will be called. Since this happens in Ruby, it can be a very expensive procedure, so use it carefully.
* ``:delete_orphans``, which will delete only the associated records that have no other relationships of the same type.
* ``:destroy_orphans``, same as above, but it takes place in Ruby.

The two orphan-destruction options are unique to Neo4j.rb. As an example of when you'd use them, imagine you are modeling tours, routes, and stops along those routes. A tour can have multiple routes, a route can have multiple stops, a stop can be in multiple routes but must have at least one. When a route is destroyed, ``:delete_orphans`` would delete only those related stops that have no other routes.

.. seealso::

  .. raw:: html

    There is also a screencast available reviewing associations:

    <iframe width="560" height="315" src="https://www.youtube.com/embed/veqIfIqtoNc" frameborder="0" allowfullscreen></iframe>



.. seealso::
  #has_many http://www.rubydoc.info/gems/activegraph/ActiveGraph/Node/HasN/ClassMethods#has_many-instance_method
  and
  #has_one http://www.rubydoc.info/gems/activegraph/ActiveGraph/Node/HasN/ClassMethods#has_one-instance_method

Association Options
~~~~~~~~~~~~~~~~~~~~~~

By default, when you call an association ``Node`` will add the ``model_class`` labels to the query (as a filter). For example:

.. code-block:: ruby

    person.friends
    # =>
    # MATCH (person125)
    # WHERE (ID(person125) = $ID_person125)
    # MATCH (person125)-[rel1:`FRIEND`]->(node3:`Person`)

The exception to this is if ``model_class: false``, in which case ``MATCH (person125)-[rel1:`FRIEND`]->(node3)``.
More advanced Neo4j users may prefer to skip adding labels to the target node, even if ``model_class != false``.
This can be accomplished on a case-by-case basis by calling the association with a `labels: false`` options argument.
For example: ``person.friends(labels: false)``.

You can also make ``labels: false`` the default settings by
creating the association with a ``labels: false`` option. For example:

.. code-block:: ruby

    class Person
      has_many :out, :friends, type: :FRIEND, model_class: self, labels: false
    end

Creating Unique Relationships
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

By including the ``unique`` option in a ``has_many`` or ``has_one`` association's method call, you can change the Cypher used to create from "CREATE" to "CREATE UNIQUE."

.. code-block:: ruby

  has_many :out, :friends, type: 'FRIENDS_WITH', model_class: :User, unique: true

Instead of ``true``, you can give one of three different options:

* ``:none``, also used ``true`` is given, will not include properties to determine whether ot not to create a unique relationship. This means that no more than one relationship of the same pairing of nodes, rel type, and direction will ever be created.
* ``:all``, which will include all set properties in rel creation. This means that if a new relationship will be created unless all nodes, type, direction, and rel properties are matched.
* ``{on: [keys]}`` will use the keys given to determine whether to create a new rel and the remaining properties will be set afterwards.

.. _node-eager_loading:


Eager Loading
~~~~~~~~~~~~~

Node supports eager loading of associations in two ways.  The first way is transparent.  When you do the following:

.. code-block:: ruby

  person.blog_posts.each do |post|
    puts post.title
    puts "Tags: #{post.tags.map(&:name).join(', ')}"
    post.comments.each do |comment|
      puts '  ' + comment.title
    end
  end

Only three Cypher queries will be made:

 * One to get the blog posts for the user
 * One to get the tags for all of the blog posts
 * One to get the comments for all of the blog posts

While three queries isn't ideal, it is better than the naive approach of one query for every call to an object's association (Thanks to `DataMapper <http://datamapper.org/why.html>`_ for the inspiration).

For those times when you need to load all of your data with one Cypher query, however, you can do the following to give `Node` a hint:

.. code-block:: ruby

  person.blog_posts.with_associations(:tags, :comments).each do |post|
    puts post.title
    puts "Tags: #{post.tags.map(&:name).join(', ')}"
    post.comments.each do |comment|
      puts '  ' + comment.title
    end
  end

All that we did here was add ``.with_associations(:tags, :comments)``.  In addition to getting all of the blog posts, this will generate a Cypher query which uses the Cypher `COLLECT()` function to efficiently roll-up all of the associated objects.  `Node` then automatically structures them into a nested set of `Node` objects for you.

You can also use ``with_associations`` with multiple levels like:

.. code-block:: ruby

  person.blog_posts.with_associations(:tags, comments: :hashtags)

You can use ``*`` to eager load relationships with variable length like:

.. code-block:: ruby

  person.blog_posts.with_associations('comments.owner.friends*')

To get fixed length relationships you can use ``*<length>`` like:

.. code-block:: ruby

  person.blog_posts.with_associations('comments.owner.friends*2')

This will eager load ``friends`` relationship till 2 levels deep.
