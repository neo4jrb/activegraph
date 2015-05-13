ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/id_property.rb:126 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/id_property.rb#L126>`_





Methods
-------



.. _`Neo4j/ActiveNode/IdProperty/ClassMethods#find_by_id`:

**#find_by_id**
  

  .. hidden-code-block:: ruby

     def find_by_id(id)
       self.where(id_property_name => id).first
     end



.. _`Neo4j/ActiveNode/IdProperty/ClassMethods#find_by_ids`:

**#find_by_ids**
  

  .. hidden-code-block:: ruby

     def find_by_ids(ids)
       self.where(id_property_name => ids).to_a
     end



.. _`Neo4j/ActiveNode/IdProperty/ClassMethods#find_by_neo_id`:

**#find_by_neo_id**
  

  .. hidden-code-block:: ruby

     def find_by_neo_id(id)
       Neo4j::Node.load(id)
     end



.. _`Neo4j/ActiveNode/IdProperty/ClassMethods#has_id_property?`:

**#has_id_property?**
  rubocop:disable Style/PredicateName

  .. hidden-code-block:: ruby

     def has_id_property?
       ActiveSupport::Deprecation.warn 'has_id_property? is deprecated and may be removed from future releases, use id_property? instead.', caller
     
       id_property?
     end



.. _`Neo4j/ActiveNode/IdProperty/ClassMethods#id_property`:

**#id_property**
  

  .. hidden-code-block:: ruby

     def id_property(name, conf = {})
       id_property_constraint(name)
       @id_property_info = {name: name, type: conf}
       TypeMethods.define_id_methods(self, name, conf)
       constraint name, type: :unique unless conf[:constraint] == false
     
       self.define_singleton_method(:find_by_id) { |key| self.where(name => key).first }
     end



.. _`Neo4j/ActiveNode/IdProperty/ClassMethods#id_property?`:

**#id_property?**
  rubocop:enable Style/PredicateName

  .. hidden-code-block:: ruby

     def id_property?
       id_property_info && !id_property_info.empty?
     end



.. _`Neo4j/ActiveNode/IdProperty/ClassMethods#id_property_info`:

**#id_property_info**
  

  .. hidden-code-block:: ruby

     def id_property_info
       @id_property_info ||= {}
     end



.. _`Neo4j/ActiveNode/IdProperty/ClassMethods#id_property_name`:

**#id_property_name**
  

  .. hidden-code-block:: ruby

     def id_property_name
       id_property_info[:name]
     end



.. _`Neo4j/ActiveNode/IdProperty/ClassMethods#primary_key`:

**#primary_key**
  

  .. hidden-code-block:: ruby

     def id_property_name
       id_property_info[:name]
     end





