Validations
===========



This mixin replace the original save method and performs validation before the save.


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   Validations/ClassMethods

   Validations/UniquenessValidator




Constants
---------





Files
-----



  * `lib/neo4j/active_node/validations.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/validations.rb#L4>`_





Methods
-------



.. _`Neo4j/ActiveNode/Validations#read_attribute_for_validation`:

**#read_attribute_for_validation**
  Implements the ActiveModel::Validation hook method.

  .. code-block:: ruby

     def read_attribute_for_validation(key)
       respond_to?(key) ? send(key) : self[key]
     end



.. _`Neo4j/ActiveNode/Validations#save`:

**#save**
  The validation process on save can be skipped by passing false. The regular Model#save method is
  replaced with this when the validations module is mixed in, which it is by default.

  .. code-block:: ruby

     def save(options = {})
       result = perform_validations(options) ? super : false
       if !result
         Neo4j::Transaction.current.failure if Neo4j::Transaction.current
       end
       result
     end



.. _`Neo4j/ActiveNode/Validations#valid?`:

**#valid?**
  

  .. code-block:: ruby

     def valid?(context = nil)
       context ||= (new_record? ? :create : :update)
       super(context)
       errors.empty?
     end





