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


**#column_names**
  

  .. hidden-code-block:: ruby

     def column_names
       klass._decl_props.keys
     end


**#create!**
  Create a model using attributes

  .. hidden-code-block:: ruby

     def create!(attributes = {})
       klass.create!(attributes)
     end


**#destroy**
  

  .. hidden-code-block:: ruby

     def destroy(object)
       object.destroy && true if valid_object?(object)
     end


**#extract_id!**
  

  .. hidden-code-block:: ruby

     def extract_id!(conditions)
       id = conditions.delete(:id)
       return if not id
     
       conditions[klass.id_property_name.to_sym] = id
     end


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


**#get**
  Get an instance by id of the model

  .. hidden-code-block:: ruby

     def get(id)
       klass.find(wrap_key(id))
     end


**#get!**
  Get an instance by id of the model

  .. hidden-code-block:: ruby

     def get!(id)
       klass.find(wrap_key(id)).tap do |node|
         fail 'No record found' if node.nil?
       end
     end


**#hasherize_order**
  

  .. hidden-code-block:: ruby

     def hasherize_order(order)
       (order || []).map { |clause| Hash[*clause] }
     end


**#i18n_scope**
  

  .. hidden-code-block:: ruby

     def i18n_scope
       :neo4j
     end





