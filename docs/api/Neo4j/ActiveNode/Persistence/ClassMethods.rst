ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/persistence.rb:102 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/persistence.rb#L102>`_





Methods
-------



.. _`Neo4j/ActiveNode/Persistence/ClassMethods#create`:

**#create**
  Creates and saves a new node

  .. code-block:: ruby

     def create(props = {})
       association_props = extract_association_attributes!(props) || {}
       new(props).tap do |obj|
         yield obj if block_given?
         obj.save
         association_props.each do |prop, value|
           obj.send("#{prop}=", value)
         end
       end
     end



.. _`Neo4j/ActiveNode/Persistence/ClassMethods#create!`:

**#create!**
  Same as #create, but raises an error if there is a problem during save.

  .. code-block:: ruby

     def create!(*args)
       props = args[0] || {}
       association_props = extract_association_attributes!(props) || {}
     
       new(*args).tap do |o|
         yield o if block_given?
         o.save!
         association_props.each do |prop, value|
           o.send("#{prop}=", value)
         end
       end
     end



.. _`Neo4j/ActiveNode/Persistence/ClassMethods#find_or_create`:

**#find_or_create**
  

  .. code-block:: ruby

     def find_or_create(find_attributes, set_attributes = {})
       on_create_attributes = set_attributes.reverse_merge(on_create_props(find_attributes))
     
       neo4j_session.query.merge(n: {self.mapped_label_names => find_attributes})
         .on_create_set(n: on_create_attributes)
         .pluck(:n).first
     end



.. _`Neo4j/ActiveNode/Persistence/ClassMethods#find_or_create_by`:

**#find_or_create_by**
  Finds the first node with the given attributes, or calls create if none found

  .. code-block:: ruby

     def find_or_create_by(attributes, &block)
       find_by(attributes) || create(attributes, &block)
     end



.. _`Neo4j/ActiveNode/Persistence/ClassMethods#find_or_create_by!`:

**#find_or_create_by!**
  Same as #find_or_create_by, but calls #create! so it raises an error if there is a problem during save.

  .. code-block:: ruby

     def find_or_create_by!(attributes, &block)
       find_by(attributes) || create!(attributes, &block)
     end



.. _`Neo4j/ActiveNode/Persistence/ClassMethods#load_entity`:

**#load_entity**
  

  .. code-block:: ruby

     def load_entity(id)
       Neo4j::Node.load(id)
     end



.. _`Neo4j/ActiveNode/Persistence/ClassMethods#merge`:

**#merge**
  

  .. code-block:: ruby

     def merge(match_attributes, optional_attrs = {})
       options = [:on_create, :on_match, :set]
       optional_attrs.assert_valid_keys(*options)
     
       optional_attrs.default = {}
       on_create_attrs, on_match_attrs, set_attrs = optional_attrs.values_at(*options)
     
       neo4j_session.query.merge(n: {self.mapped_label_names => match_attributes})
         .on_create_set(n: on_create_props(on_create_attrs))
         .on_match_set(n: on_match_props(on_match_attrs))
         .break.set(n: set_attrs)
         .pluck(:n).first
     end





