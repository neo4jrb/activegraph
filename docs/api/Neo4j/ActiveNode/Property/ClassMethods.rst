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



.. _`Neo4j/ActiveNode/Property/ClassMethods#association_key?`:

**#association_key?**
  

  .. code-block:: ruby

     def association_key?(key)
       association_method_keys.include?(key.to_sym)
     end



.. _`Neo4j/ActiveNode/Property/ClassMethods#extract_association_attributes!`:

**#extract_association_attributes!**
  Extracts keys from attributes hash which are associations of the model
  TODO: Validate separately that relationships are getting the right values?  Perhaps also store the values and persist relationships on save?

  .. code-block:: ruby

     def extract_association_attributes!(attributes)
       return unless contains_association?(attributes)
       attributes.each_with_object({}) do |(key, _), result|
         result[key] = attributes.delete(key) if self.association_key?(key)
       end
     end





