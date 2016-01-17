ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/has_n.rb:206 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/has_n.rb#L206>`_





Methods
-------



.. _`Neo4j/ActiveNode/HasN/ClassMethods#association?`:

**#association?**
  rubocop:enable Style/PredicateName

  .. code-block:: ruby

     def association?(name)
       !!associations[name.to_sym]
     end



.. _`Neo4j/ActiveNode/HasN/ClassMethods#associations`:

**#associations**
  

  .. code-block:: ruby

     def associations
       @associations ||= {}
     end



.. _`Neo4j/ActiveNode/HasN/ClassMethods#associations_keys`:

**#associations_keys**
  

  .. code-block:: ruby

     def associations_keys
       @associations_keys ||= associations.keys
     end



.. _`Neo4j/ActiveNode/HasN/ClassMethods#has_association?`:

**#has_association?**
  :nocov:

  .. code-block:: ruby

     def has_association?(name)
       ActiveSupport::Deprecation.warn 'has_association? is deprecated and may be removed from future releases, use association? instead.', caller
     
       association?(name)
     end



.. _`Neo4j/ActiveNode/HasN/ClassMethods#has_many`:

**#has_many**
  For defining an "has many" association on a model.  This defines a set of methods on
  your model instances.  For instance, if you define the association on a Person model:
  
  
  .. code-block:: ruby
  
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
  
    .. code-block:: ruby
  
      company.people.where(age: 40).vehicles
  
  Arguments:
    **direction:**
      **Available values:** ``:in``, ``:out``, or ``:both``.
  
      Refers to the relative to the model on which the association is being defined.
  
      Example:
  
      .. code-block:: ruby
  
        Person.has_many :out, :posts, type: :wrote
  
      means that a `WROTE` relationship goes from a `Person` node to a `Post` node
  
    **name:**
      The name of the association.  The affects the methods which are created (see above).
      The name is also used to form default assumptions about the model which is being referred to
  
      Example:
  
      .. code-block:: ruby
  
        Person.has_many :out, :posts, type: :wrote
  
      will assume a `model_class` option of ``'Post'`` unless otherwise specified
  
    **options:** A ``Hash`` of options.  Allowed keys are:
      *type*: The Neo4j relationship type.  This option is required unless either the
        `origin` or `rel_class` options are specified
  
      *origin*: The name of the association from another model which the `type` and `model_class`
        can be gathered.
  
        Example:
  
        .. code-block:: ruby
  
          # `model_class` of `Post` is assumed here
          Person.has_many :out, :posts, origin: :author
  
          Post.has_one :in, :author, type: :has_author, model_class: :Person
  
      *model_class*: The model class to which the association is referring.  Can be a
        Symbol/String (or an ``Array`` of same) with the name of the `ActiveNode` class,
        `false` to specify any model, or nil to specify that it should be guessed.
  
      *rel_class*: The ``ActiveRel`` class to use for this association.  Can be either a
        model object ``include`` ing ``ActiveRel`` or a Symbol/String (or an ``Array`` of same).
        **A Symbol or String is recommended** to avoid load-time issues
  
      *dependent*: Enables deletion cascading.
        **Available values:** ``:delete``, ``:delete_orphans``, ``:destroy``, ``:destroy_orphans``
        (note that the ``:destroy_orphans`` option is known to be "very metal".  Caution advised)

  .. code-block:: ruby

     def has_many(direction, name, options = {}) # rubocop:disable Style/PredicateName
       name = name.to_sym
       build_association(:has_many, direction, name, options)
     
       define_has_many_methods(name)
     end



.. _`Neo4j/ActiveNode/HasN/ClassMethods#has_one`:

**#has_one**
  For defining an "has one" association on a model.  This defines a set of methods on
  your model instances.  For instance, if you define the association on a Person model:
  
  has_one :out, :vehicle, type: :has_vehicle
  
  This would define the methods: ``#vehicle``, ``#vehicle=``, and ``.vehicle``.
  
  See :ref:`#has_many <Neo4j/ActiveNode/HasN/ClassMethods#has_many>` for anything
  not specified here

  .. code-block:: ruby

     def has_one(direction, name, options = {}) # rubocop:disable Style/PredicateName
       name = name.to_sym
       build_association(:has_one, direction, name, options)
     
       define_has_one_methods(name)
     end



.. _`Neo4j/ActiveNode/HasN/ClassMethods#inherited`:

**#inherited**
  make sure the inherited classes inherit the <tt>_decl_rels</tt> hash

  .. code-block:: ruby

     def inherited(klass)
       klass.instance_variable_set(:@associations, associations.clone)
       @associations_keys = klass.associations_keys.clone
       super
     end





