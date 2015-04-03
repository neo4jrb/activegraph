ActiveNode
==========




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   ActiveNode/Rels

   ActiveNode/HasN

   ActiveNode/Query

   ActiveNode/Scope

   ActiveNode/Labels

   ActiveNode/Property

   ActiveNode/Callbacks

   ActiveNode/Dependent

   ActiveNode/Initialize

   ActiveNode/Reflection

   ActiveNode/IdProperty

   ActiveNode/ClassMethods

   ActiveNode/OrmAdapter

   ActiveNode/Persistence

   ActiveNode/Validations

   ActiveNode/QueryMethods




Constants
---------



  * WRAPPED_CLASSES

  * WRAPPED_MODELS

  * MODELS_FOR_LABELS_CACHE

  * USES_CLASSNAME

  * ILLEGAL_PROPS



Files
-----



  * `lib/neo4j/active_node.rb:23 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node.rb#L23>`_

  * `lib/neo4j/active_node/rels.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/rels.rb#L1>`_

  * `lib/neo4j/active_node/has_n.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/has_n.rb#L1>`_

  * `lib/neo4j/active_node/query.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query.rb#L2>`_

  * `lib/neo4j/active_node/scope.rb:3 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/scope.rb#L3>`_

  * `lib/neo4j/active_node/labels.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/labels.rb#L2>`_

  * `lib/neo4j/active_node/property.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/property.rb#L1>`_

  * `lib/neo4j/active_node/callbacks.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/callbacks.rb#L2>`_

  * `lib/neo4j/active_node/dependent.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/dependent.rb#L2>`_

  * `lib/neo4j/active_node/reflection.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/reflection.rb#L1>`_

  * `lib/neo4j/active_node/id_property.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/id_property.rb#L1>`_

  * `lib/neo4j/active_node/orm_adapter.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/orm_adapter.rb#L4>`_

  * `lib/neo4j/active_node/persistence.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/persistence.rb#L1>`_

  * `lib/neo4j/active_node/validations.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/validations.rb#L2>`_

  * `lib/neo4j/active_node/query_methods.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query_methods.rb#L2>`_

  * `lib/neo4j/active_node/has_n/association.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/has_n/association.rb#L4>`_

  * `lib/neo4j/active_node/query/query_proxy.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy.rb#L2>`_

  * `lib/neo4j/active_node/query/query_proxy_link.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_link.rb#L2>`_

  * `lib/neo4j/active_node/query/query_proxy_methods.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_methods.rb#L2>`_

  * `lib/neo4j/active_node/query/query_proxy_enumerable.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_enumerable.rb#L2>`_

  * `lib/neo4j/active_node/dependent/association_methods.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/dependent/association_methods.rb#L2>`_

  * `lib/neo4j/active_node/dependent/query_proxy_methods.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/dependent/query_proxy_methods.rb#L2>`_

  * `lib/neo4j/active_node/query/query_proxy_find_in_batches.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_find_in_batches.rb#L2>`_





Methods
-------



.. _`Neo4j/ActiveNode#==`:

**#==**
  

  .. hidden-code-block:: ruby

     def ==(other)
       other.class == self.class && other.id == id
     end



.. _`Neo4j/ActiveNode#[]`:

**#[]**
  Returning nil when we get ActiveAttr::UnknownAttributeError from ActiveAttr

  .. hidden-code-block:: ruby

     def read_attribute(name)
       super(name)
     rescue ActiveAttr::UnknownAttributeError
       nil
     end



.. _`Neo4j/ActiveNode#_create_node`:

**#_create_node**
  

  .. hidden-code-block:: ruby

     def _create_node(*args)
       session = self.class.neo4j_session
       props = self.class.default_property_values(self)
       props.merge!(args[0]) if args[0].is_a?(Hash)
       set_classname(props)
       labels = self.class.mapped_label_names
       session.create_node(props, labels)
     end



.. _`Neo4j/ActiveNode#_persisted_obj`:

**#_persisted_obj**
  Returns the value of attribute _persisted_obj

  .. hidden-code-block:: ruby

     def _persisted_obj
       @_persisted_obj
     end



.. _`Neo4j/ActiveNode#_rels_delegator`:

**#_rels_delegator**
  

  .. hidden-code-block:: ruby

     def _rels_delegator
       fail "Can't access relationship on a non persisted node" unless _persisted_obj
       _persisted_obj
     end



.. _`Neo4j/ActiveNode#add_label`:

**#add_label**
  adds one or more labels

  .. hidden-code-block:: ruby

     def add_label(*label)
       @_persisted_obj.add_label(*label)
     end



.. _`Neo4j/ActiveNode#as`:

**#as**
  Starts a new QueryProxy with the starting identifier set to the given argument and QueryProxy caller set to the node instance.
  This method does not exist within QueryProxy and can only be used to start a new chain.

  .. hidden-code-block:: ruby

     def as(node_var)
       self.class.query_proxy(node: node_var, caller: self).match_to(self)
     end



.. _`Neo4j/ActiveNode#association_cache`:

**#association_cache**
  Returns the current association cache. It is in the format
  { :association_name => { :hash_of_cypher_string => [collection] }}

  .. hidden-code-block:: ruby

     def association_cache
       @association_cache ||= {}
     end



.. _`Neo4j/ActiveNode#association_instance_fetch`:

**#association_instance_fetch**
  

  .. hidden-code-block:: ruby

     def association_instance_fetch(cypher_string, association_obj, &block)
       association_instance_get(cypher_string, association_obj) || association_instance_set(cypher_string, block.call, association_obj)
     end



.. _`Neo4j/ActiveNode#association_instance_get`:

**#association_instance_get**
  Returns the specified association instance if it responds to :loaded?, nil otherwise.

  .. hidden-code-block:: ruby

     def association_instance_get(cypher_string, association_obj)
       return if association_cache.nil? || association_cache.empty?
       lookup_obj = cypher_hash(cypher_string)
       reflection = association_reflection(association_obj)
       return if reflection.nil?
       association_cache[reflection.name] ? association_cache[reflection.name][lookup_obj] : nil
     end



.. _`Neo4j/ActiveNode#association_instance_get_by_reflection`:

**#association_instance_get_by_reflection**
  

  .. hidden-code-block:: ruby

     def association_instance_get_by_reflection(reflection_name)
       association_cache[reflection_name]
     end



.. _`Neo4j/ActiveNode#association_instance_set`:

**#association_instance_set**
  Caches an association result. Unlike ActiveRecord, which stores results in @association_cache using { :association_name => [collection_result] },
  ActiveNode stores it using { :association_name => { :hash_string_of_cypher => [collection_result] }}.
  This is necessary because an association name by itself does not take into account :where, :limit, :order, etc,... so it's prone to error.

  .. hidden-code-block:: ruby

     def association_instance_set(cypher_string, collection_result, association_obj)
       return collection_result if Neo4j::Transaction.current
       cache_key = cypher_hash(cypher_string)
       reflection = association_reflection(association_obj)
       return if reflection.nil?
       if @association_cache[reflection.name]
         @association_cache[reflection.name][cache_key] = collection_result
       else
         @association_cache[reflection.name] = {cache_key => collection_result}
       end
       collection_result
     end



.. _`Neo4j/ActiveNode#association_query_proxy`:

**#association_query_proxy**
  

  .. hidden-code-block:: ruby

     def association_query_proxy(name, options = {})
       self.class.association_query_proxy(name, {start_object: self}.merge(options))
     end



.. _`Neo4j/ActiveNode#association_reflection`:

**#association_reflection**
  

  .. hidden-code-block:: ruby

     def association_reflection(association_obj)
       self.class.reflect_on_association(association_obj.name)
     end



.. _`Neo4j/ActiveNode#cache_key`:

**#cache_key**
  

  .. hidden-code-block:: ruby

     def cache_key
       if self.new_record?
         "#{model_cache_key}/new"
       elsif self.respond_to?(:updated_at) && !self.updated_at.blank?
         "#{model_cache_key}/#{neo_id}-#{self.updated_at.utc.to_s(:number)}"
       else
         "#{model_cache_key}/#{neo_id}"
       end
     end



.. _`Neo4j/ActiveNode#called_by`:

**#called_by**
  Returns the value of attribute called_by

  .. hidden-code-block:: ruby

     def called_by
       @called_by
     end



.. _`Neo4j/ActiveNode#called_by=`:

**#called_by=**
  Sets the attribute called_by

  .. hidden-code-block:: ruby

     def called_by=(value)
       @called_by = value
     end



.. _`Neo4j/ActiveNode#clear_association_cache`:

**#clear_association_cache**
  Clears out the association cache.

  .. hidden-code-block:: ruby

     def clear_association_cache #:nodoc:
       association_cache.clear if _persisted_obj
     end



.. _`Neo4j/ActiveNode#convert_properties_to`:

**#convert_properties_to**
  

  .. hidden-code-block:: ruby

     def convert_properties_to(medium, properties)
       converter = medium == :ruby ? :to_ruby : :to_db
     
       properties.each_with_object({}) do |(attr, value), new_attributes|
         next new_attributes if skip_conversion?(attr, value)
         new_attributes[attr] = converted_property(primitive_type(attr.to_sym), value, converter)
       end
     end



.. _`Neo4j/ActiveNode#cypher_hash`:

**#cypher_hash**
  Uses the cypher generated by a QueryProxy object, complete with params, to generate a basic non-cryptographic hash
  for use in @association_cache.

  .. hidden-code-block:: ruby

     def cypher_hash(cypher_string)
       cypher_string.hash.abs
     end



.. _`Neo4j/ActiveNode#default_properties`:

**#default_properties**
  

  .. hidden-code-block:: ruby

     def default_properties
       @default_properties ||= Hash.new(nil)
       # keys = self.class.default_properties.keys
       # _persisted_obj.props.reject{|key| !keys.include?(key)}
     end



.. _`Neo4j/ActiveNode#default_properties=`:

**#default_properties=**
  

  .. hidden-code-block:: ruby

     def default_properties=(properties)
       keys = self.class.default_properties.keys
       @default_properties = properties.select { |key| keys.include?(key) }
     end



.. _`Neo4j/ActiveNode#default_property`:

**#default_property**
  

  .. hidden-code-block:: ruby

     def default_property(key)
       default_properties[key.to_sym]
     end



.. _`Neo4j/ActiveNode#dependent_children`:

**#dependent_children**
  

  .. hidden-code-block:: ruby

     def dependent_children
       @dependent_children ||= []
     end



.. _`Neo4j/ActiveNode#destroy`:

**#destroy**
  :nodoc:

  .. hidden-code-block:: ruby

     def destroy #:nodoc:
       tx = Neo4j::Transaction.new
       run_callbacks(:destroy) { super }
     rescue
       @_deleted = false
       @attributes = @attributes.dup
       tx.mark_failed
       raise
     ensure
       tx.close if tx
     end



.. _`Neo4j/ActiveNode#destroyed?`:

**#destroyed?**
  Returns +true+ if the object was destroyed.

  .. hidden-code-block:: ruby

     def destroyed?
       @_deleted || (!new_record? && !exist?)
     end



.. _`Neo4j/ActiveNode#eql?`:

**#eql?**
  

  .. hidden-code-block:: ruby

     def ==(other)
       other.class == self.class && other.id == id
     end



.. _`Neo4j/ActiveNode#exist?`:

**#exist?**
  

  .. hidden-code-block:: ruby

     def exist?
       _persisted_obj && _persisted_obj.exist?
     end



.. _`Neo4j/ActiveNode#freeze`:

**#freeze**
  

  .. hidden-code-block:: ruby

     def freeze
       @attributes.freeze
       self
     end



.. _`Neo4j/ActiveNode#frozen?`:

**#frozen?**
  

  .. hidden-code-block:: ruby

     def frozen?
       @attributes.frozen?
     end



.. _`Neo4j/ActiveNode#hash`:

**#hash**
  

  .. hidden-code-block:: ruby

     def hash
       id.hash
     end



.. _`Neo4j/ActiveNode#id`:

**#id**
  

  .. hidden-code-block:: ruby

     def id
       id = neo_id
       id.is_a?(Integer) ? id : nil
     end



.. _`Neo4j/ActiveNode#init_on_load`:

**#init_on_load**
  called when loading the node from the database

  .. hidden-code-block:: ruby

     def init_on_load(persisted_node, properties)
       self.class.extract_association_attributes!(properties)
       @_persisted_obj = persisted_node
       changed_attributes && changed_attributes.clear
       @attributes = attributes.merge(properties.stringify_keys)
       self.default_properties = properties
       @attributes = convert_properties_to :ruby, @attributes
     end



.. _`Neo4j/ActiveNode#initialize`:

**#initialize**
  

  .. hidden-code-block:: ruby

     def initialize(attributes = {}, options = {})
       super(attributes, options)
     
       send_props(@relationship_props) if persisted? && !@relationship_props.nil?
     end



.. _`Neo4j/ActiveNode#labels`:

**#labels**
  

  .. hidden-code-block:: ruby

     def labels
       @_persisted_obj.labels
     end



.. _`Neo4j/ActiveNode#neo4j_obj`:

**#neo4j_obj**
  

  .. hidden-code-block:: ruby

     def neo4j_obj
       _persisted_obj || fail('Tried to access native neo4j object on a non persisted object')
     end



.. _`Neo4j/ActiveNode#neo_id`:

**#neo_id**
  

  .. hidden-code-block:: ruby

     def neo_id
       _persisted_obj ? _persisted_obj.neo_id : nil
     end



.. _`Neo4j/ActiveNode#new?`:

**#new?**
  Returns +true+ if the record hasn't been saved to Neo4j yet.

  .. hidden-code-block:: ruby

     def new_record?
       !_persisted_obj
     end



.. _`Neo4j/ActiveNode#new_record?`:

**#new_record?**
  Returns +true+ if the record hasn't been saved to Neo4j yet.

  .. hidden-code-block:: ruby

     def new_record?
       !_persisted_obj
     end



.. _`Neo4j/ActiveNode#persisted?`:

**#persisted?**
  Returns +true+ if the record is persisted, i.e. it's not a new record and it was not destroyed

  .. hidden-code-block:: ruby

     def persisted?
       !new_record? && !destroyed?
     end



.. _`Neo4j/ActiveNode#props`:

**#props**
  

  .. hidden-code-block:: ruby

     def props
       attributes.reject { |_, v| v.nil? }.symbolize_keys
     end



.. _`Neo4j/ActiveNode#query_as`:

**#query_as**
  Returns a Query object with the current node matched the specified variable name

  .. hidden-code-block:: ruby

     def query_as(node_var)
       self.class.query_as(node_var).where("ID(#{node_var})" => self.neo_id)
     end



.. _`Neo4j/ActiveNode#read_attribute`:

**#read_attribute**
  Returning nil when we get ActiveAttr::UnknownAttributeError from ActiveAttr

  .. hidden-code-block:: ruby

     def read_attribute(name)
       super(name)
     rescue ActiveAttr::UnknownAttributeError
       nil
     end



.. _`Neo4j/ActiveNode#read_attribute_for_validation`:

**#read_attribute_for_validation**
  Implements the ActiveModel::Validation hook method.

  .. hidden-code-block:: ruby

     def read_attribute_for_validation(key)
       respond_to?(key) ? send(key) : self[key]
     end



.. _`Neo4j/ActiveNode#reload`:

**#reload**
  

  .. hidden-code-block:: ruby

     def reload
       return self if new_record?
       clear_association_cache
       changed_attributes && changed_attributes.clear
       unless reload_from_database
         @_deleted = true
         freeze
       end
       self
     end



.. _`Neo4j/ActiveNode#reload_from_database`:

**#reload_from_database**
  

  .. hidden-code-block:: ruby

     def reload_from_database
       # TODO: - Neo4j::IdentityMap.remove_node_by_id(neo_id)
       if reloaded = self.class.load_entity(neo_id)
         send(:attributes=, reloaded.attributes)
       end
       reloaded
     end



.. _`Neo4j/ActiveNode#remove_label`:

**#remove_label**
  Removes one or more labels
  Be careful, don't remove the label representing the Ruby class.

  .. hidden-code-block:: ruby

     def remove_label(*label)
       @_persisted_obj.remove_label(*label)
     end



.. _`Neo4j/ActiveNode#save`:

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



.. _`Neo4j/ActiveNode#save!`:

**#save!**
  Persist the object to the database.  Validations and Callbacks are included
  by default but validation can be disabled by passing :validate => false
  to #save!  Creates a new transaction.

  .. hidden-code-block:: ruby

     def save!(*args)
       fail RecordInvalidError, self unless save(*args)
     end



.. _`Neo4j/ActiveNode#send_props`:

**#send_props**
  

  .. hidden-code-block:: ruby

     def send_props(hash)
       hash.each { |key, value| self.send("#{key}=", value) }
     end



.. _`Neo4j/ActiveNode#serializable_hash`:

**#serializable_hash**
  

  .. hidden-code-block:: ruby

     def serializable_hash(*args)
       super.merge(id: id)
     end



.. _`Neo4j/ActiveNode#serialized_properties`:

**#serialized_properties**
  

  .. hidden-code-block:: ruby

     def serialized_properties
       self.class.serialized_properties
     end



.. _`Neo4j/ActiveNode#to_key`:

**#to_key**
  Returns an Enumerable of all (primary) key attributes
  or nil if model.persisted? is false

  .. hidden-code-block:: ruby

     def to_key
       persisted? ? [id] : nil
     end



.. _`Neo4j/ActiveNode#touch`:

**#touch**
  :nodoc:

  .. hidden-code-block:: ruby

     def touch(*) #:nodoc:
       run_callbacks(:touch) { super }
     end



.. _`Neo4j/ActiveNode#update`:

**#update**
  Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
  If saving fails because the resource is invalid then false will be returned.

  .. hidden-code-block:: ruby

     def update(attributes)
       self.attributes = process_attributes(attributes)
       save
     end



.. _`Neo4j/ActiveNode#update!`:

**#update!**
  Same as {#update_attributes}, but raises an exception if saving fails.

  .. hidden-code-block:: ruby

     def update!(attributes)
       self.attributes = process_attributes(attributes)
       save!
     end



.. _`Neo4j/ActiveNode#update_attribute`:

**#update_attribute**
  Convenience method to set attribute and #save at the same time

  .. hidden-code-block:: ruby

     def update_attribute(attribute, value)
       send("#{attribute}=", value)
       self.save
     end



.. _`Neo4j/ActiveNode#update_attribute!`:

**#update_attribute!**
  Convenience method to set attribute and #save! at the same time

  .. hidden-code-block:: ruby

     def update_attribute!(attribute, value)
       send("#{attribute}=", value)
       self.save!
     end



.. _`Neo4j/ActiveNode#update_attributes`:

**#update_attributes**
  Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
  If saving fails because the resource is invalid then false will be returned.

  .. hidden-code-block:: ruby

     def update(attributes)
       self.attributes = process_attributes(attributes)
       save
     end



.. _`Neo4j/ActiveNode#update_attributes!`:

**#update_attributes!**
  Same as {#update_attributes}, but raises an exception if saving fails.

  .. hidden-code-block:: ruby

     def update!(attributes)
       self.attributes = process_attributes(attributes)
       save!
     end



.. _`Neo4j/ActiveNode#valid?`:

**#valid?**
  

  .. hidden-code-block:: ruby

     def valid?(context = nil)
       context     ||= (new_record? ? :create : :update)
       super(context)
       errors.empty?
     end



.. _`Neo4j/ActiveNode#wrapper`:

**#wrapper**
  Implements the Neo4j::Node#wrapper and Neo4j::Relationship#wrapper method
  so that we don't have to care if the node is wrapped or not.

  .. hidden-code-block:: ruby

     def wrapper
       self
     end





