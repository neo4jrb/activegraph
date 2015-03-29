Validations
===========




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   Validations/ClassMethods

   Validations/UniquenessValidator




Constants
---------





Files
-----



  * lib/neo4j/active_node/validations.rb:4





Methods
-------


**#perform_validations**
  

  .. hidden-code-block:: ruby

     def perform_validations(options = {})
       perform_validation = case options
                            when Hash
                              options[:validate] != false
                            end
     
       if perform_validation
         valid?(options.is_a?(Hash) ? options[:context] : nil)
       else
         true
       end
     end


**#read_attribute_for_validation**
  Implements the ActiveModel::Validation hook method.

  .. hidden-code-block:: ruby

     def read_attribute_for_validation(key)
       respond_to?(key) ? send(key) : self[key]
     end


**#save**
  The validation process on save can be skipped by passing false. The regular Model#save method is
  replaced with this when the validations module is mixed in, which it is by default.

  .. hidden-code-block:: ruby

     def save(options = {})
       result = perform_validations(options) ? super : false
       if !result
         Neo4j::Transaction.current.failure if Neo4j::Transaction.current
       end
       result
     end


**#valid?**
  

  .. hidden-code-block:: ruby

     def valid?(context = nil)
       context     ||= (new_record? ? :create : :update)
       super(context)
       errors.empty?
     end





