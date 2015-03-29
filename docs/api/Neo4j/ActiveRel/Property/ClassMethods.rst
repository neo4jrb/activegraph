ClassMethods
============




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   




Constants
---------





Files
-----



  * lib/neo4j/active_rel/property.rb:28





Methods
-------


**#creates_unique_rel**
  

  .. hidden-code-block:: ruby

     def creates_unique_rel
       @unique = true
     end


**#end_class**
  

  .. hidden-code-block:: ruby

     alias_method :end_class,    :to_class


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


**#load_entity**
  

  .. hidden-code-block:: ruby

     def load_entity(id)
       Neo4j::Node.load(id)
     end


**#start_class**
  

  .. hidden-code-block:: ruby

     alias_method :start_class,  :from_class


**#unique?**
  

  .. hidden-code-block:: ruby

     def unique?
       !!@unique
     end





