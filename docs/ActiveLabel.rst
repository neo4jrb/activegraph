ActiveLabel
===========

``ActiveNode`` provides an ability to define inheritance of models which also gives subclasess the labels of their parent models.  In Ruby, however, inheritence of classes is not sufficient.  Sometimes is makes more sense to be able to build a module which defines behavior (or "concerns") which could be applied to any model.  This is what ``ActiveLabel`` provides.

``ActiveLabel`` modules can be defined in two ways:

 * Default: Where the module's behavior is always defined on the ``ActiveNode`` model and the model's nodes always have a corresponding label in Neo4j
 * Optional: Where the module's behavior is defined on the class only when the model's nodes have a corresponding label in Neo4j

.. code-block:: ruby

  class Person
    include Neo4j::ActiveNode

    property :name, type: String

    label :HasAddress
    label :Destroyable
  end

  class Organization
    include Neo4j::ActiveNode

    property :title, type: String

    label :HasAddress
    label :Destroyable
  end


.. code-block:: ruby

  class Address
    property :line1, type: String
    property :line2, type: String
    property :country, type: String
    property :postal_code, type: String
  end

  module HasAddress
    include Neo4j::ActiveLabel

    included do
      has_one :out, :address, type: :HAS_ADDRESS
    end

    module InstanceMethods
      def distance_from(has_address_object)
        address.distance_from(has_address_object.address)
      end
    end
  end


.. code-block:: ruby

  module Destroyable
    include Neo4j::ActiveLabel

    follows_label :Destroyed

    included do
      property :destroyed_at, type: DateTime
    end

    module InstanceMethods
      def destroy
        destroyed_at = Time.now

        super
      end
    end

    module ClassMethods
      def destroyed_recently
        all.where("#{identity}.destroyed_at > ?", 1.week.ago)
      end
    end
  end


Creating
--------

If an ``ActiveLabel`` does not declare ``follows_label``, creating a node will attach the corresponding label.  Otherwise you must trigger the attachment of the label:

.. code-block:: ruby

  # Node gets both `Person` and `HasAddress` labels
  person = Person.create

  # `Destroyed' label is added.  `mark_destroyed` method is automatically defined via `follows_label` definition
  person.label_as_destroyed

  # `Destroyed' label is removed
  person.label_as_not_destroyed

Querying
--------

``ActiveLabel`` allows your Ruby module to act like a model class.  However, since you can add a label to any module, you can query for nodes across modules:

.. code-block:: ruby

  Destroyable.all

  HasAddress.as(:obj).address.where(postal_code: '12345').pluck('DISTINCT obj')

By default this returns all nodes for all models where the ``ActiveLabel`` module is defined.  If ``follows_label`` is declared, this returns just those nodes which have the label.

By defining the ``follows_label``, some methods are automatically provided to allow you to filter and interrogate:

.. code-block:: ruby

  Person.labeled_as_destroyed

  Person.first.labeled_as_destroyed?

Associations
~~~~~~~~~~~~

You can even create associations to traverse to labels:

.. code-block:: ruby

  class Organization
    include Neo4j::ActiveNode

    has_many :out, :addressables, type: :HAS_ADDRESSABLE_OBJECT, label_class: :HasAddress

    # `model_class` acts as a filter to the `label_class` argument.  Both `model_class` and `label_class` can be arrays
    has_many :out, :addressable_people, type: :HAS_ADDRESSABLE_OBJECT, label_class: :HasAddress, model_class: :Person
  end

