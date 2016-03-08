ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/id_property.rb:124 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/id_property.rb#L124>`_





Methods
-------



.. _`Neo4j/ActiveNode/IdProperty/ClassMethods#find_by_id`:

**#find_by_id**
  

  .. code-block:: ruby

     def find_by_id(id)
       all.where(id_property_name => id).first
     end



.. _`Neo4j/ActiveNode/IdProperty/ClassMethods#find_by_ids`:

**#find_by_ids**
  

  .. code-block:: ruby

     def find_by_ids(ids)
       all.where(id_property_name => ids).to_a
     end



.. _`Neo4j/ActiveNode/IdProperty/ClassMethods#find_by_neo_id`:

**#find_by_neo_id**
  

  .. code-block:: ruby

     def find_by_neo_id(id)
       Neo4j::Node.load(id)
     end



.. _`Neo4j/ActiveNode/IdProperty/ClassMethods#has_id_property?`:

**#has_id_property?**
  rubocop:disable Style/PredicateName

  .. code-block:: ruby

     def has_id_property?
       ActiveSupport::Deprecation.warn 'has_id_property? is deprecated and may be removed from future releases, use id_property? instead.', caller
     
       id_property?
     end



.. _`Neo4j/ActiveNode/IdProperty/ClassMethods#id_property`:

**#id_property**
  

  .. code-block:: ruby

     def id_property(name, conf = {})
       self.manual_id_property = true
       Neo4j::Session.on_next_session_available do |_|
         @id_property_info = {name: name, type: conf}
         TypeMethods.define_id_methods(self, name, conf)
         constraint(name, type: :unique) unless conf[:constraint] == false
       end
     end



.. _`Neo4j/ActiveNode/IdProperty/ClassMethods#id_property?`:

**#id_property?**
  rubocop:enable Style/PredicateName

  .. code-block:: ruby

     def id_property?
       id_property_info && !id_property_info.empty?
     end



.. _`Neo4j/ActiveNode/IdProperty/ClassMethods#id_property_info`:

**#id_property_info**
  

  .. code-block:: ruby

     def id_property_info
       @id_property_info ||= {}
     end



.. _`Neo4j/ActiveNode/IdProperty/ClassMethods#id_property_name`:

**#id_property_name**
  

  .. code-block:: ruby

     def id_property_name
       id_property_info[:name]
     end



.. _`Neo4j/ActiveNode/IdProperty/ClassMethods#manual_id_property`:

**#manual_id_property**
  Returns the value of attribute manual_id_property

  .. code-block:: ruby

     def manual_id_property
       @manual_id_property
     end



.. _`Neo4j/ActiveNode/IdProperty/ClassMethods#manual_id_property=`:

**#manual_id_property=**
  Sets the attribute manual_id_property

  .. code-block:: ruby

     def manual_id_property=(value)
       @manual_id_property = value
     end



.. _`Neo4j/ActiveNode/IdProperty/ClassMethods#manual_id_property?`:

**#manual_id_property?**
  

  .. code-block:: ruby

     def manual_id_property?
       !!manual_id_property
     end



.. _`Neo4j/ActiveNode/IdProperty/ClassMethods#primary_key`:

**#primary_key**
  

  .. code-block:: ruby

     def id_property_name
       id_property_info[:name]
     end





