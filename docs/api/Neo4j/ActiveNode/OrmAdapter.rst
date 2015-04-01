OrmAdapter
==========




.. toctree::
   :maxdepth: 3
   :titlesonly:


   OrmAdapter/ClassMethods

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/orm_adapter.rb:9 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/orm_adapter.rb#L9>`_





Methods
-------


.. _OrmAdapter_column_names:

**#column_names**
  

  .. hidden-code-block:: ruby

     def column_names
       klass._decl_props.keys
     end


.. _OrmAdapter_create!:

**#create!**
  Create a model using attributes

  .. hidden-code-block:: ruby

     def create!(attributes = {})
       klass.create!(attributes)
     end


.. _OrmAdapter_destroy:

**#destroy**
  

  .. hidden-code-block:: ruby

     def destroy(object)
       object.destroy && true if valid_object?(object)
     end


.. _OrmAdapter_find_all:

**#find_all**
  Find all models matching conditions

  .. hidden-code-block:: ruby

     def find_all(options = {})
       conditions, order, limit, offset = extract_conditions!(options)
       extract_id!(conditions)
       order = hasherize_order(order)
     
       result = klass.where(conditions)
       result = result.order(order) unless order.empty?
       result = result.skip(offset) if offset
       result = result.limit(limit) if limit
       result.to_a
     end


.. _OrmAdapter_find_first:

**#find_first**
  Find the first instance matching conditions

  .. hidden-code-block:: ruby

     def find_first(options = {})
       conditions, order = extract_conditions!(options)
       extract_id!(conditions)
       order = hasherize_order(order)
     
       result = klass.where(conditions)
       result = result.order(order) unless order.empty?
       result.first
     end


.. _OrmAdapter_get:

**#get**
  Get an instance by id of the model

  .. hidden-code-block:: ruby

     def get(id)
       klass.find(wrap_key(id))
     end


.. _OrmAdapter_get!:

**#get!**
  Get an instance by id of the model

  .. hidden-code-block:: ruby

     def get!(id)
       klass.find(wrap_key(id)).tap do |node|
         fail 'No record found' if node.nil?
       end
     end


.. _OrmAdapter_i18n_scope:

**#i18n_scope**
  

  .. hidden-code-block:: ruby

     def i18n_scope
       :neo4j
     end





