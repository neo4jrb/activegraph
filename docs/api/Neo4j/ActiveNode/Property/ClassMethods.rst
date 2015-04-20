ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/property.rb:11 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/property.rb#L11>`_





Methods
-------



.. _`Neo4j/ActiveNode/Property/ClassMethods#extract_association_attributes!`:

**#extract_association_attributes!**
  Extracts keys from attributes hash which are relationships of the model
  TODO: Validate separately that relationships are getting the right values?  Perhaps also store the values and persist relationships on save?

  .. hidden-code-block:: ruby

     def extract_association_attributes!(attributes)
       attributes.each_key do |key|
         if self.association?(key)
           @_association_attributes ||= {}
           @_association_attributes[key] = attributes.delete(key)
         end
       end
       # We want to return nil if this was not set, we do not want to return an empty array
       @_association_attributes
     end





