Property
========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   Property/ClassMethods




Constants
---------





Files
-----



  * `lib/neo4j/active_node/property.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/property.rb#L2>`_





Methods
-------



.. _`Neo4j/ActiveNode/Property#[]`:

**#[]**
  Returning nil when we get ActiveAttr::UnknownAttributeError from ActiveAttr

  .. code-block:: ruby

     def read_attribute(name)
       super(name)
     rescue ActiveAttr::UnknownAttributeError
       nil
     end



.. _`Neo4j/ActiveNode/Property#_persisted_obj`:

**#_persisted_obj**
  Returns the value of attribute _persisted_obj

  .. code-block:: ruby

     def _persisted_obj
       @_persisted_obj
     end



.. _`Neo4j/ActiveNode/Property#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(attributes = nil)
       super(attributes)
       @attributes ||= Hash[self.class.attributes_nil_hash]
       send_props(@relationship_props) if _persisted_obj && !@relationship_props.nil?
     end



.. _`Neo4j/ActiveNode/Property#read_attribute`:

**#read_attribute**
  Returning nil when we get ActiveAttr::UnknownAttributeError from ActiveAttr

  .. code-block:: ruby

     def read_attribute(name)
       super(name)
     rescue ActiveAttr::UnknownAttributeError
       nil
     end



.. _`Neo4j/ActiveNode/Property#send_props`:

**#send_props**
  

  .. code-block:: ruby

     def send_props(hash)
       return hash if hash.blank?
       hash.each { |key, value| self.send("#{key}=", value) }
     end





