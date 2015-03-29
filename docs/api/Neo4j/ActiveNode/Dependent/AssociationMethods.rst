AssociationMethods
==================




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   




Constants
---------





Files
-----



  * lib/neo4j/active_node/dependent/association_methods.rb:4





Methods
-------


**#add_destroy_callbacks**
  

  .. hidden-code-block:: ruby

     def add_destroy_callbacks(model)
       return if dependent.nil?
     
       model.before_destroy(&method("dependent_#{dependent}_callback"))
     rescue NameError
       raise "Unknown dependent option #{dependent}"
     end


**#dependent_delete_callback**
  Callback methods

  .. hidden-code-block:: ruby

     def dependent_delete_callback(object)
       object.association_query_proxy(name).delete_all
     end


**#dependent_delete_orphans_callback**
  

  .. hidden-code-block:: ruby

     def dependent_delete_orphans_callback(object)
       object.as(:self).unique_nodes(self, :self, :n, :other_rel).query.delete(:n, :other_rel).exec
     end


**#dependent_destroy_callback**
  

  .. hidden-code-block:: ruby

     def dependent_destroy_callback(object)
       object.association_query_proxy(name).each_for_destruction(object, &:destroy)
     end


**#dependent_destroy_orphans_callback**
  

  .. hidden-code-block:: ruby

     def dependent_destroy_orphans_callback(object)
       object.as(:self).unique_nodes(self, :self, :n, :other_rel).each_for_destruction(object, &:destroy)
     end


**#valid_dependent_value?**
  

  .. hidden-code-block:: ruby

     def valid_dependent_value?(value)
       return true if value.nil?
     
       self.respond_to?("dependent_#{value}_callback", true)
     end


**#validate_dependent**
  

  .. hidden-code-block:: ruby

     def validate_dependent(value)
       fail ArgumentError, "Invalid dependent value: #{value.inspect}" if not valid_dependent_value?(value)
     end





