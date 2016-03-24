ActiveNode
==========

ActiveNode is the ActiveRecord replacement module for Rails. Its syntax should be familiar for ActiveRecord users but has some unique qualities.

To use ActiveNode, include Neo4j::ActiveNode in a class.

.. code-block:: ruby

    class Post
      include Neo4j::ActiveNode
    end

Properties
----------

All properties for Neo4j::ActiveNode objects must be declared (unlike neo4j-core nodes). Properties are declared using the property method which is the same as attribute from the active_attr gem.

Example:

.. code-block:: ruby

    class Post
      include Neo4j::ActiveNode
      property :title, index: :exact
      property :text, default: 'bla bla bla'
      property :score, type: Integer, default: 0

      validates :title, :presence => true
      validates :score, numericality: { only_integer: true }

      before_save do
        self.score = score * 100
      end

      has_n :friends
    end

Properties can be indexed using the index argument on the property method, see example above.

See the Properties section for additional information.


.. seealso::
  .. raw:: html

    There is also a screencast available reviewing properties:

    <iframe width="560" height="315" src="https://www.youtube.com/embed/2pCSQkHkPC8" frameborder="0" allowfullscreen></iframe>

Labels
~~~~~~

By default ``ActiveNode`` takes your model class' name and uses it directly as the Neo4j label for the nodes it represents.  This even includes using the module namespace of the class.  That is, the class  ``MyClass`` in the ``MyModule`` module will have the label ``MyModule::MyClass``.  To change this behavior, see the :term:`module_handling` configuration variable.

Additionally you can change the name of a particular ``ActiveNode`` by using ``mapped_label_name`` like so:

.. code-block:: ruby

    class Post
      include Neo4j::ActiveNode

      self.mapped_label_name = 'BlogPost'
    end

Indexes
~~~~~~~

To declare a index on a property

.. code-block:: ruby

    class Person
      include Neo4j::ActiveNode
      property :name, index: :exact
    end

Only exact index is currently possible.

Indexes can also be declared like this:

.. code-block:: ruby

    class Person
      include Neo4j::ActiveNode
      property :name
      index :name
    end

Constraints
~~~~~~~~~~~

You can declare that a property should have a unique value.

.. code-block:: ruby

    class Person
      property :id_number, constraint: :unique # will raise an exception if id_number is not unique
    end

Notice an unique validation is not enough to be 100% sure that a property is unique (because of concurrency issues, just like ActiveRecord). Constraints can also be declared just like indexes separately, see above.

Labels
~~~~~~

The class name maps directly to the label.  In the following case both the class name and label are ``Post``

.. code-block:: ruby

    class Post
      include Neo4j::ActiveNode
    end

If you want to specify a different label for your class you can use ``mapped_label_name``:

.. code-block:: ruby

    class Post
      include Neo4j::ActiveNode

      self.mapped_label_name = 'BlogPost'
    end

If you would like to use multiple labels you can use class inheritance.  In the following case object created with the `Article` model would have both `Post` and `Article` labels.  When querying `Article` both labels are required on the nodes as well.

.. code-block:: ruby

    class Post
      include Neo4j::ActiveNode
    end

    class Article < Post
    end



Serialization
~~~~~~~~~~~~~

Pass a property name as a symbol to the serialize method if you want to save a hash or an array with mixed object types* to the database.

.. code-block:: ruby

    class Student
      include Neo4j::ActiveNode

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

Enums
~~~~~~
You can declare special properties that maps an integer value in the database with a set of keywords, like ``ActiveRecord::Enum``

.. code-block:: ruby

    class Media
      include Neo4j::ActiveNode

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

By default, every ``enum`` property will be defined as ``unique``, to improve query performances. If you want to disable this, simply pass ``_index: false`` to ``enum``:

.. code-block:: ruby

    class Media
      include Neo4j::ActiveNode

      enum type: [:image, :video, :unknown], _index: false
    end


.. _activenode-wrapping:

Wrapping
--------

When loading a node from the database there is a process to determine which ``ActiveNode`` model to choose for wrapping the node.  If nothing is configured on your part then when a node is created labels will be saved representing all of the classes in the hierarchy.

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
      include Neo4j::ActiveNode

      include Neo4j::Timestamps # will give model created_at and updated_at timestamps
      include Neo4j::Timestamps::Created # will give model created_at timestamp
      include Neo4j::Timestamps::Updated # will give model updated_at timestamp
    end

Validation
----------

Support the Active Model validation, such as:

validates :age, presence: true
validates_uniqueness_of :name, :scope => :adult

id property (primary key)
-------------------------

Unique IDs are automatically created for all nodes using SecureRandom::uuid. See Unique IDs for details.

Associations
------------

``has_many`` and ``has_one`` associations can also be defined on ``ActiveNode`` models to make querying and creating relationships easier.

.. code-block:: ruby

    class Post
      include Neo4j::ActiveNode
      has_many :in, :comments, origin: :post
      has_one :out, :author, type: :author, model_class: :Person
    end

    class Comment
      include Neo4j::ActiveNode
      has_one :out, :post, type: :post
      has_one :out, :author, type: :author, model_class: :Person
    end

    class Person
      include Neo4j::ActiveNode
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
    post.comments.authors.posts # All posts of people who have commented on the post.  Still makes just one query

You can create associations

.. code-block:: ruby

    post.comments = [comment1, comment2]  # Removes all existing relationships
    post.comments << comment3             # Creates new relationship

    comment.post = post1                  # Removes all existing relationships

.. seealso::

  .. raw:: html

    There is also a screencast available reviewing associations:

    <iframe width="560" height="315" src="https://www.youtube.com/embed/veqIfIqtoNc" frameborder="0" allowfullscreen></iframe>



.. seealso::
  :ref:`#has_many <Neo4j/ActiveNode/HasN/ClassMethods#has_many>`
  and
  :ref:`#has_one <Neo4j/ActiveNode/HasN/ClassMethods#has_one>`


Creating Unique Relationships
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

By including the ``unique`` option in a ``has_many`` or ``has_one`` association's method call, you can change the Cypher used to create from "CREATE" to "CREATE UNIQUE."

.. code-block:: ruby

  has_many :out, :friends, type: 'FRIENDS_WITH', model_class: :User, unique: true

Instead of ``true``, you can give one of three different options:

* ``:none``, also used ``true`` is given, will not include properties to determine whether ot not to create a unique relationship. This means that no more than one relationship of the same pairing of nodes, rel type, and direction will ever be created.
* ``:all``, which will include all set properties in rel creation. This means that if a new relationship will be created unless all nodes, type, direction, and rel properties are matched.
* ``{on: [keys]}`` will use the keys given to determine whether to create a new rel and the remaining properties will be set afterwards.

.. _active_node-eager_loading:


Eager Loading
~~~~~~~~~~~~~

ActiveNode supports eager loading of associations in two ways.  The first way is transparent.  When you do the following:

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

For those times when you need to load all of your data with one Cypher query, however, you can do the following to give `ActiveNode` a hint:

.. code-block:: ruby

  person.blog_posts.with_associations(:tags, :comments).each do |post|
    puts post.title
    puts "Tags: #{post.tags.map(&:name).join(', ')}"
    post.comments.each do |comment|
      puts '  ' + comment.title
    end
  end

All that we did here was add ``.with_associations(:tags, :comments)``.  In addition to getting all of the blog posts, this will generate a Cypher query which uses the Cypher `COLLECT()` function to efficiently roll-up all of the associated objects.  `ActiveNode` then automatically structures them into a nested set of `ActiveNode` objects for you.

