ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_rel/property.rb:34 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_rel/property.rb#L34>`_





Methods
-------



.. _`Neo4j/ActiveRel/Property/ClassMethods#creates_unique`:

**#creates_unique**
  

  .. code-block:: ruby

     def creates_unique
       @creates_unique = true
     end



.. _`Neo4j/ActiveRel/Property/ClassMethods#creates_unique?`:

**#creates_unique?**
  

  .. code-block:: ruby

     def creates_unique?
       !!@creates_unique
     end



.. _`Neo4j/ActiveRel/Property/ClassMethods#creates_unique_rel`:

**#creates_unique_rel**
  

  .. code-block:: ruby

     def creates_unique_rel
       warning = <<-WARNING
     creates_unique_rel() is deprecated and will be removed from future releases,
     use creates_unique() instead.
     WARNING
     
       ActiveSupport::Deprecation.warn(warning, caller)
     
       creates_unique
     end



.. _`Neo4j/ActiveRel/Property/ClassMethods#end_class`:

**#end_class**
  

  .. code-block:: ruby

     alias_method :end_class,    :to_class



.. _`Neo4j/ActiveRel/Property/ClassMethods#extract_association_attributes!`:

**#extract_association_attributes!**
  Extracts keys from attributes hash which are relationships of the model
  TODO: Validate separately that relationships are getting the right values?  Perhaps also store the values and persist relationships on save?

  .. code-block:: ruby

     def extract_association_attributes!(attributes)
       return if attributes.blank?
       {}.tap do |relationship_props|
         attributes.each_key do |key|
           relationship_props[key] = attributes.delete(key) if [:from_node, :to_node].include?(key)
         end
       end
     end



.. _`Neo4j/ActiveRel/Property/ClassMethods#id_property_name`:

**#id_property_name**
  

  .. code-block:: ruby

     def id_property_name
       false
     end



.. _`Neo4j/ActiveRel/Property/ClassMethods#load_entity`:

**#load_entity**
  

  .. code-block:: ruby

     def load_entity(id)
       Neo4j::Node.load(id)
     end



.. _`Neo4j/ActiveRel/Property/ClassMethods#start_class`:

**#start_class**
  

  .. code-block:: ruby

     alias_method :start_class,  :from_class



.. _`Neo4j/ActiveRel/Property/ClassMethods#unique?`:

**#unique?**
  

  .. code-block:: ruby

     def creates_unique?
       !!@creates_unique
     end





