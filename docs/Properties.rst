Properties
==========

In classes that mixin the ``Neo4j::ActiveNode`` or ``Neo4j::ActiveRel`` modules, properties must be declared using the ``property`` class method. It requires a single argument, a symbol that will correspond with the getter and setter as well as the property in the database.

.. code-block:: ruby

    class Post
      include Neo4j::ActiveNode

      property :title
    end

Two options are also available to both node and relationship models. They are:

- ``type``, to specify the expected class of the stored value in Ruby
- ``default``, a default value to set when the property is ``nil``

Node models have two more options:

- ``index: :exact`` to declare an exact index in the database
- ``constraint: :unique`` to declare a unique constraint

Note that a constraint is a type of index, so there is neither need nor ability to use both.

Finally, you can serialize properties as JSON with the `serialize` class method.

In practice, you can put it all together like this:

.. code-block:: ruby

  class Post
    include Neo4j::ActiveNode

    property :title, type: String, default: 'This ia new post', index: :exact
    property :links

    serialize :links
  end

You will now be able to set the ``title`` property through mass-assignment (``Post.new(title: 'My Title')``) or by calling the `title=` method. You can also give a hash of links (``{ homepage: 'http://neo4jrb.io', twitter: 'https://twitter.com/neo4jrb' }``) to the ``links`` property and it will be saved as JSON to the db.

Undeclared Properties
---------------------

Neo4j, being schemaless as far as the database is concerned, does not require that property keys be defined ahead of time. As a result, it's possible (and sometimes desirable) to set properties on the node that are not also defined on the database. For instance:

.. code-block:: ruby

  Neo4j::Node.create({ property: 'MyProp', secret_val: 123 }, :Post)
  post = Post.first
  post.secret_val
  => NoMethodError: undefined method `secret_val`...

In this case, simply adding the ``secret_val`` property to your model will make it available through the ``secret_val`` method. Alternatively, you can also access the properties of the "unwrapped node" through ``post._persisted_obj.props``. See the Neo4j::Core API for more details about working with CypherNode objects.

Types and Conversion
____________________

The ``type`` option has some interesting qualities that are worth being aware of when developing. It defines the type of object that you expect when returning the value to Ruby, _not_ the type that will be stored in the database. There are a few types available by default.

- String
- Integer
- Fixnum
- BigDecimal
- Date
- Time
- DateTime
- Boolean (TrueClass or FalseClass)

Declaring a type is not necessary and, in some cases, is better for performance. You should omit a type declaration if you are confident in the consistency of data going to/from the database.

.. code-block:: ruby

  class Post
    include Neo4j::ActiveNode

    property :score, type: Integer
    property :created_at, type: DateTime
  end

In this model, the ``score`` property's type will ensure that String interpretations of numbers are always converted to Integer when you return the property in Ruby. As an added bonus, it will convert before saving to the database because Neo4j is capable of storing Ints natively, so you won't have to convert every time.
DateTimes, however, are a different beast, because Neo4j cannot handle Ruby's native formats. To work around this, type converter knows to change the DateTime object into an Integer before saving and then, when loading the node, it will convert the Integer back into a DateTime.

This magic comes with a cost. DateTime conversion in particular is expensive and if you are obsessed with speed, you'll find that it slows you down. A tip for those users is to set your timestamps to ``type: Integer`` and you will end up with Unix timestamps that you can manipulate if/when you need them in friendlier formats.

Custom Converters
_________________

It is possible to define custom converters for types not handled natively by the gem.

.. code-block:: ruby

  class RangeConverter
    class << self
      def primitive_type
        String
      end

      def convert_type
        Range
      end

      def to_db(value)
        value.to_s
      end

      def to_ruby(value)
        ends = value.to_s.split('..').map { |d| Integer(d) }
        ends[0]..ends[1]
      end
      alias_method :call, :to_ruby
    end

    include Neo4j::Shared::Typecaster
  end

This would allow you to use ``property :my_prop, type: Range`` in a model.
Each method and the ``alias_method`` call is required. Make sure the module inclusion happens at the end of the file.

``primitive_type`` is used to fool ActiveAttr's type converters, which only recognize a few basic Ruby classes.

``convert_type`` must match the constant given to the ``type`` option.

``to_db`` provides logic required to transform your value into the class defined by ``primitive_type``. It will store the object in the database as this type.

``to_ruby`` provides logic to transform the DB-provided value back into the class expected by code using the property. It shuld return an object of the type set in ``convert_type``.

Note the ``alias_method`` to make ``to_ruby`` respond to `call`. This is to provide compatibility with the ``ActiveAttr`` dependency.

An optional method, ``converted?(value)`` can be defined. This should return a boolean indicating whether a value is already of the expected type for Neo4j.
