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



.. _`Neo4j/ActiveNode/OrmAdapter#column_names`:

**#column_names**
  

  .. code-block:: ruby

     def column_names
       klass._decl_props.keys
     end



.. _`Neo4j/ActiveNode/OrmAdapter#create!`:

**#create!**
  Create a model using attributes

  .. code-block:: ruby

     def create!(attributes = {})
       klass.create!(attributes)
     end



.. _`Neo4j/ActiveNode/OrmAdapter#destroy`:

**#destroy**
  

  .. code-block:: ruby

     def destroy(object)
       object.destroy && true if valid_object?(object)
     end



.. _`Neo4j/ActiveNode/OrmAdapter#find_all`:

**#find_all**
  Find all models matching conditions

  .. code-block:: ruby

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



.. _`Neo4j/ActiveNode/OrmAdapter#find_first`:

**#find_first**
  Find the first instance matching conditions

  .. code-block:: ruby

     def find_first(options = {})
       conditions, order = extract_conditions!(options)
       extract_id!(conditions)
       order = hasherize_order(order)
     
       result = klass.where(conditions)
       result = result.order(order) unless order.empty?
       result.first
     end



.. _`Neo4j/ActiveNode/OrmAdapter#get`:

**#get**
  Get an instance by id of the model

  .. code-block:: ruby

     def get(id)
       klass.find_by(klass.id_property_name => wrap_key(id))
     end



.. _`Neo4j/ActiveNode/OrmAdapter#get!`:

**#get!**
  Get an instance by id of the model

  .. code-block:: ruby

     def get!(id)
       klass.find(wrap_key(id)).tap do |node|
         fail 'No record found' if node.nil?
       end
     end



.. _`Neo4j/ActiveNode/OrmAdapter#i18n_scope`:

**#i18n_scope**
  

  .. code-block:: ruby

     def i18n_scope
       :neo4j
     end





