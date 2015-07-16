ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_rel/property.rb:27 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/property.rb#L27>`_





Methods
-------



.. _`Neo4j/ActiveRel/Property/ClassMethods#creates_unique_rel`:

**#creates_unique_rel**
  

  .. hidden-code-block:: ruby

     def creates_unique_rel
       @unique = true
     end



.. _`Neo4j/ActiveRel/Property/ClassMethods#end_class`:

**#end_class**
  

  .. hidden-code-block:: ruby

     alias_method :end_class,    :to_class



.. _`Neo4j/ActiveRel/Property/ClassMethods#extract_association_attributes!`:

**#extract_association_attributes!**
  Extracts keys from attributes hash which are relationships of the model
  TODO: Validate separately that relationships are getting the right values?  Perhaps also store the values and persist relationships on save?

  .. hidden-code-block:: ruby

     def extract_association_attributes!(attributes)
       {}.tap do |relationship_props|
         attributes.each_key do |key|
           relationship_props[key] = attributes.delete(key) if [:from_node, :to_node].include?(key)
         end
       end
     end



.. _`Neo4j/ActiveRel/Property/ClassMethods#id_property_name`:

**#id_property_name**
  

  .. hidden-code-block:: ruby

     def id_property_name
       false
     end



.. _`Neo4j/ActiveRel/Property/ClassMethods#load_entity`:

**#load_entity**
  

  .. hidden-code-block:: ruby

     def load_entity(id)
       Neo4j::Node.load(id)
     end



.. _`Neo4j/ActiveRel/Property/ClassMethods#start_class`:

**#start_class**
  

  .. hidden-code-block:: ruby

     alias_method :start_class,  :from_class



.. _`Neo4j/ActiveRel/Property/ClassMethods#unique?`:

**#unique?**
  

  .. hidden-code-block:: ruby

     def unique?
       !!@unique
     end





