ClassMethods
============




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/id_property.rb:114 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/id_property.rb#L114>`_





Methods
-------


**#find_by_id**
  

  .. hidden-code-block:: ruby

     def find_by_id(id)
       self.where(id_property_name => id).first
     end


**#find_by_ids**
  

  .. hidden-code-block:: ruby

     def find_by_ids(ids)
       self.where(id_property_name => ids).to_a
     end


**#find_by_neo_id**
  

  .. hidden-code-block:: ruby

     def find_by_neo_id(id)
       Neo4j::Node.load(id)
     end


**#has_id_property?**
  rubocop:disable Style/PredicateName

  .. hidden-code-block:: ruby

     def has_id_property?
       ActiveSupport::Deprecation.warn 'has_id_property? is deprecated and may be removed from future releases, use id_property? instead.', caller
     
       id_property?
     end


**#id_property**
  

  .. hidden-code-block:: ruby

     def id_property(name, conf = {})
       begin
         if id_property?
           unless mapped_label.uniqueness_constraints[:property_keys].include?([name])
             drop_constraint(id_property_name, type: :unique)
           end
         end
       rescue Neo4j::Server::CypherResponse::ResponseError
       end
     
       @id_property_info = {name: name, type: conf}
       TypeMethods.define_id_methods(self, name, conf)
       constraint name, type: :unique
     
       self.define_singleton_method(:find_by_id) do |key|
         self.where(name => key).first
       end
     end


**#id_property?**
  rubocop:enable Style/PredicateName

  .. hidden-code-block:: ruby

     def id_property?
       id_property_info && !id_property_info.empty?
     end


**#id_property_info**
  

  .. hidden-code-block:: ruby

     def id_property_info
       @id_property_info ||= {}
     end


**#id_property_name**
  

  .. hidden-code-block:: ruby

     def id_property_name
       id_property_info[:name]
     end


**#primary_key**
  

  .. hidden-code-block:: ruby

     def id_property_name
       id_property_info[:name]
     end





