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
      property :updated_at  # will automatically be set when model changes
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

What follows is an overview of adding associations to models. For more detailed information, see Declared Relationships.

has_many and has_one associations can also be defined on ActiveNode models to make querying and creating relationships easier.

.. code-block:: ruby

    class Post
      include Neo4j::ActiveNode
      has_many :in, :comments, origin: :post
      has_one :out, :author, type: :author, model_class: Person
    end

    class Comment
      include Neo4j::ActiveNode
      has_one :out, :post, type: :post
      has_one :out, :author, type: :author, model_class: Person
    end

    class Person
      include Neo4j::ActiveNode
      has_many :in, :posts, origin: :author
      has_many :in, :comments, origin: :author
    end

You can query associations:

.. code-block:: ruby

    post.comments.to_a          # Array of comments
    comment.post                # Post object
    comment.post.comments       # Original comment and all of it's siblings.  Makes just one query
    post.comments.authors.posts # All posts of people who have commented on the post.  Still makes just one query
    You can create associations

    post.comments = [comment1, comment2]  # Removes all existing relationships
    post.comments << comment3             # Creates new relationship

    comment.post = post1                  # Removes all existing relationships
