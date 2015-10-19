UniquenessValidator
===================






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/validations.rb:23 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/validations.rb#L23>`_





Methods
-------



.. _`Neo4j/ActiveNode/Validations/UniquenessValidator#found`:

**#found**
  

  .. code-block:: ruby

     def found(record, attribute, value)
       conditions = scope_conditions(record)
     
       # TODO: Added as find(:name => nil) throws error
       value = '' if value.nil?
     
       conditions[attribute] = options[:case_sensitive] ? value : /#{Regexp.escape(value.to_s)}/i
     
       found = record.class.as(:result).where(conditions)
       found = found.where_not(neo_id: record.neo_id) if record._persisted_obj
       found
     end



.. _`Neo4j/ActiveNode/Validations/UniquenessValidator#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(options)
       super(options.reverse_merge(case_sensitive: true))
     end



.. _`Neo4j/ActiveNode/Validations/UniquenessValidator#message`:

**#message**
  

  .. code-block:: ruby

     def message(instance)
       super || 'has already been taken'
     end



.. _`Neo4j/ActiveNode/Validations/UniquenessValidator#scope_conditions`:

**#scope_conditions**
  

  .. code-block:: ruby

     def scope_conditions(instance)
       Array(options[:scope] || []).inject({}) do |conditions, key|
         conditions.merge(key => instance[key])
       end
     end



.. _`Neo4j/ActiveNode/Validations/UniquenessValidator#validate_each`:

**#validate_each**
  

  .. code-block:: ruby

     def validate_each(record, attribute, value)
       return unless found(record, attribute, value).exists?
     
       record.errors.add(attribute, :taken, options.except(:case_sensitive, :scope).merge(value: value))
     end





