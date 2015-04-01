ClassMethods
============




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/has_n.rb:79 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/has_n.rb#L79>`_





Methods
-------


.. _ClassMethods_association?:

**#association?**
  rubocop:enable Style/PredicateName
  :nocov:

  .. hidden-code-block:: ruby

     def association?(name)
       !!associations[name.to_sym]
     end


.. _ClassMethods_associations:

**#associations**
  

  .. hidden-code-block:: ruby

     def associations
       @associations || {}
     end


.. _ClassMethods_has_association?:

**#has_association?**
  :nocov:
  rubocop:disable Style/PredicateName

  .. hidden-code-block:: ruby

     def has_association?(name)
       ActiveSupport::Deprecation.warn 'has_association? is deprecated and may be removed from future releases, use association? instead.', caller
     
       association?(name)
     end


.. _ClassMethods_has_many:

**#has_many**
  For defining an "has many" association on a model.  This defines a set of methods on
  your model instances.  For instance, if you define the association on a Person model:
  
  has_many :out, :vehicles, type: :has_vehicle
  
  This would define the following methods:
  
  **#vehicles**
    Returns a QueryProxy object.  This is an Enumerable object and thus can be iterated
    over.  It also has the ability to accept class-level methods from the Vehicle model
    (including calls to association methods)
  
  **#vehicles=**
    Takes an array of Vehicle objects and replaces all current ``:HAS_VEHICLE`` relationships
    with new relationships refering to the specified objects
  
  **.vehicles**
    Returns a QueryProxy object.  This would represent all ``Vehicle`` objects associated with
    either all ``Person`` nodes (if ``Person.vehicles`` is called), or all ``Vehicle`` objects
    associated with the ``Person`` nodes thus far represented in the QueryProxy chain.
    For example:
      ``company.people.where(age: 40).vehicles``

  .. hidden-code-block:: ruby

     def has_many(direction, name, options = {}) # rubocop:disable Style/PredicateName
       name = name.to_sym
       build_association(:has_many, direction, name, options)
     
       define_has_many_methods(name)
     end


.. _ClassMethods_has_one:

**#has_one**
  rubocop:disable Style/PredicateName

  .. hidden-code-block:: ruby

     def has_one(direction, name, options = {}) # rubocop:disable Style/PredicateName
       name = name.to_sym
       build_association(:has_one, direction, name, options)
     
       define_has_one_methods(name)
     end


.. _ClassMethods_inherited:

**#inherited**
  make sure the inherited classes inherit the <tt>_decl_rels</tt> hash

  .. hidden-code-block:: ruby

     def inherited(klass)
       klass.instance_variable_set(:@associations, associations.clone)
       super
     end





