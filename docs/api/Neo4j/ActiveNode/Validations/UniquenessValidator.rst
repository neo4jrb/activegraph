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


**#found**
  

  .. hidden-code-block:: ruby

     def found(record, attribute, value)
       conditions = scope_conditions(record)
     
       # TODO: Added as find(:name => nil) throws error
       value = '' if value.nil?
     
       conditions[attribute] = options[:case_sensitive] ? value : /^#{Regexp.escape(value.to_s)}$/i
     
       found = record.class.as(:result).where(conditions)
       found = found.where('ID(result) <> {record_neo_id}').params(record_neo_id: record.neo_id) if record.persisted?
       found
     end


**#initialize**
  

  .. hidden-code-block:: ruby

     def initialize(options)
       super(options.reverse_merge(case_sensitive: true))
     end


**#message**
  

  .. hidden-code-block:: ruby

     def message(instance)
       super || 'has already been taken'
     end


**#scope_conditions**
  

  .. hidden-code-block:: ruby

     def scope_conditions(instance)
       Array(options[:scope] || []).inject({}) do |conditions, key|
         conditions.merge(key => instance[key])
       end
     end


**#validate_each**
  

  .. hidden-code-block:: ruby

     def validate_each(record, attribute, value)
       return unless found(record, attribute, value).exists?
     
       record.errors.add(attribute, :taken, options.except(:case_sensitive, :scope).merge(value: value))
     end





