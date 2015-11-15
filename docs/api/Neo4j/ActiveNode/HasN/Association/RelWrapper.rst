RelWrapper
==========



Provides the interface needed to interact with the ActiveRel query factory.


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/has_n/association/rel_wrapper.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/has_n/association/rel_wrapper.rb#L3>`_





Methods
-------



.. _`Neo4j/ActiveNode/HasN/Association/RelWrapper#create_method`:

**#create_method**
  

  .. code-block:: ruby

     def create_method
       creates_unique? ? :create_unique : :create
     end



.. _`Neo4j/ActiveNode/HasN/Association/RelWrapper#creates_unique`:

**#creates_unique**
  

  .. code-block:: ruby

     def creates_unique(option = :none)
       option = :none if option == true
       @creates_unique = option
     end



.. _`Neo4j/ActiveNode/HasN/Association/RelWrapper#creates_unique?`:

**#creates_unique?**
  

  .. code-block:: ruby

     def creates_unique?
       !!@creates_unique
     end



.. _`Neo4j/ActiveNode/HasN/Association/RelWrapper#creates_unique_option`:

**#creates_unique_option**
  

  .. code-block:: ruby

     def creates_unique_option
       @creates_unique || :none
     end



.. _`Neo4j/ActiveNode/HasN/Association/RelWrapper#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(association, properties = {})
       @association = association
       @properties = properties
       @type = association.relationship_type(true)
       creates_unique(association.creates_unique_option) if association.unique?
     end



.. _`Neo4j/ActiveNode/HasN/Association/RelWrapper#persisted?`:

**#persisted?**
  

  .. code-block:: ruby

     def persisted?
       false
     end



.. _`Neo4j/ActiveNode/HasN/Association/RelWrapper#properties`:

**#properties**
  Returns the value of attribute properties

  .. code-block:: ruby

     def properties
       @properties
     end



.. _`Neo4j/ActiveNode/HasN/Association/RelWrapper#properties=`:

**#properties=**
  Sets the attribute properties

  .. code-block:: ruby

     def properties=(value)
       @properties = value
     end



.. _`Neo4j/ActiveNode/HasN/Association/RelWrapper#props_for_create`:

**#props_for_create**
  Returns the value of attribute properties

  .. code-block:: ruby

     def properties
       @properties
     end



.. _`Neo4j/ActiveNode/HasN/Association/RelWrapper#type`:

**#type**
  Returns the value of attribute type

  .. code-block:: ruby

     def type
       @type
     end



.. _`Neo4j/ActiveNode/HasN/Association/RelWrapper#unique?`:

**#unique?**
  

  .. code-block:: ruby

     def creates_unique?
       !!@creates_unique
     end





