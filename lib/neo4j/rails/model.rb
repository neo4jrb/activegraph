class Neo4j::Model
  include Neo4j::NodeMixin
  include ActiveModel::Validations
  include ActiveModel::Dirty
  include ActiveModel::MassAssignmentSecurity

  extend ActiveModel::Naming
  extend ActiveModel::Callbacks
  extend Neo4j::Validations::ClassMethods
  define_model_callbacks :create, :save, :update, :destroy


  UniquenessValidator = Neo4j::Validations::UniquenessValidator

  class RecordInvalidError < RuntimeError
    attr_reader :record

    def initialize(record)
      @record = record
      super(@record.errors.full_messages.join(", "))
    end
  end

  # --------------------------------------
  # Initialize
  # --------------------------------------

  def initialize(*)
  end

  def init_on_create(*args) # :nodoc:
    super()
    self.attributes=args[0] if args[0].respond_to?(:each_pair)
    @_created_record = true
  end

  # --------------------------------------
  # Identity
  # --------------------------------------

  def id
    neo_id.nil? ? nil : neo_id.to_s
  end

  def to_param
    persisted? ? neo_id.to_s : nil
  end

  # Returns an Enumerable of all (primary) key attributes
  # or nil if model.persisted? is false
  def to_key
    persisted? ? [:id] : nil
  end


  # enables ActiveModel::Dirty and Validation
  def method_missing(method_id, *args, &block)
    if !self.class.attribute_methods_generated?
      self.class.define_attribute_methods(self.class._decl_props.keys)
      # try again
      send(method_id, *args, &block)
    end
  end

  # redefine this methods so that ActiveModel::Dirty will work
  def []=(key, new_value)
    key = key.to_s
    unless key[0] == ?_
      old_value = self.send(:[], key)
      attribute_will_change!(key) unless old_value == new_value
    end
    Neo4j::Rails::Transaction.running? ? super : Neo4j::Rails::Transaction.run { super }
  end

  def attribute_will_change!(attr)
    begin
      value = __send__(:[], attr)
      value = value.duplicable? ? value.clone : value
    rescue TypeError, NoMethodError
    end
    changed_attributes[attr] = value
  end


  def read_attribute_for_validation(key)
    respond_to?(key) ? send(key) : self[key]
  end

  def attributes=(values)
    sanitize_for_mass_assignment(values).each do |k, v|
      if respond_to?("#{k}=")
        send("#{k}=", v)
      else
        self[k] = v
      end
    end
  end


  # Updates this resource with all the attributes from the passed-in Hash and requests that the record be saved.
  # If the saving fails because of a connection or remote service error, an exception will be raised.
  # If saving fails because the resource is invalid then false will be returned.
  def update_attributes(attributes)
    Neo4j::Rails::Transaction.running? ? update_attributes_in_tx(attributes) : Neo4j::Rails::Transaction.run { update_attributes_in_tx(attributes) }
  end

  def update_attributes_in_tx(attributes)
    self.attributes=attributes
    save
  end

  def update_attributes!(attributes)
    Neo4j::Rails::Transaction.running? ? update_attributes_in_tx!(attributes) : Neo4j::Rails::Transaction.run { update_attributes_in_tx!(attributes) }
  end

  def update_attributes_in_tx!(attributes)
    self.attributes=attributes
    save!
  end

  def update_nested_attributes(rel_type, clazz, id, attr)
    puts "update_nested_attributes #{rel_type} clazz: #{clazz} id: #{id}, attr:#{attr.inspect}, has_one #{has_one}"
    if new?
      puts "  NEW !"
      outgoing(rel_type)<<clazz.new(attr)
    else
      # we have a node that was created with the #create method - has real relationships
      # does it contain the given nested attr
      puts "  id = #{id}"
      puts "HAS OUTGOING"
      # if id == nil  then we are looking in a has_one relatinship
      if id.nil?
        found = outgoing(rel_type).first
      else
        # this is a has_n relationship, find which one we want to update
        outgoing(rel_type).each { |x| puts x.id }
        found = outgoing(rel_type).find { |n| n.id == id }
      end
      puts "  found #{found}"
      if found
        # it already exist, so update that one then
        found.update_attributes_in_tx(attr)
      else
        # does not exist, create a new one
        new_node = clazz.new(attr)
        saved = new_node.save
        outgoing(rel_type) << new_node if saved
      end
    end


  end

  def delete
    super
    @_deleted = true
    @_persisted = false
  end

  def save
    valid = valid?
    if valid
      # if we are trying to save a value then we should create a real node
      if Neo4j::Rails::Transaction.running?
        _run_save_callbacks { save_in_tx }
      else
        Neo4j::Rails::Transaction.run { _run_save_callbacks { valid = save_in_tx } }
      end
      @_created_record = false
      true
    else
      # if not valid we should rollback the transaction so that the changes does not take place.
      # no point failing the transaction if we have created a model with 'new'
      Neo4j::Rails::Transaction.fail if Neo4j::Rails::Transaction.running? && !_java_node.kind_of?(Neo4j::Value)
      false
    end
    valid
  end

  def save_in_tx
    valid = true
#    _run_save_callbacks do
    if _java_node.kind_of?(Neo4j::Value)
      node = Neo4j::Node.new(props)
      valid = _java_node.save_nested(node)
      init_on_load(node)
      init_on_create
    end

    if  new_record?
      _run_create_callbacks { clear_changes }
    else
      _run_update_callbacks { clear_changes }
    end
    valid
  end

  def clear_changes
    @previously_changed = changes
    @changed_attributes.clear
  end

  def save!
    raise RecordInvalidError.new(self) unless save
  end

  # Returns if the record is persisted, i.e. it’s not a new record and it was not destroyed
  def persisted?
    !new_record? && !destroyed?
  end

  def to_model
    self
  end

  # Returns true if this object hasn’t been saved yet — that is, a record for the object doesn’t exist yet; otherwise, returns false.
  def new_record?()
    # it is new if the model has been created with either the new or create method
    new? || @_created_record == true
  end

  def new?
    _java_node.kind_of?(Neo4j::Value)
  end

  def del
    @_deleted = true
    super
  end

  def destroy
    Neo4j::Rails::Transaction.running? ? _run_update_callbacks { del } : Neo4j::Rails::Transaction.run { _run_update_callbacks { del } }
  end

  def destroyed?()
    @_deleted
  end


  # --------------------------------------
  # Class Methods
  # --------------------------------------

  class << self
    # returns a value object instead of creating a new node
    def new(*args)
      value = Neo4j::Value.new
      wrapped = self.orig_new
      wrapped.init_on_load(value)
      wrapped.attributes=args[0] if args[0].respond_to?(:each_pair)

      wrapped.class._decl_rels.each_pair do |field, dsl|

        meta = class << wrapped;
          self;
        end

        wrapped.class._decl_rels.each_pair do |field, dsl|
          meta.send(:define_method, field) do
            if new?
              value.outgoing(dsl.namespace_type)
            else
              self.outgoing(dsl.namespace_type)
            end
          end if dsl.direction == :outgoing

          meta.send(:define_method, field) do
            # TODO
            raise "NOT IMPLEMENTED FOR #new method, please create a new model with the create method instead"
          end if dsl.direction == :incoming
        end
      end

      wrapped
    end

    # Handle Model.find(params[:id])
    def find(*args)
      if args.length == 1 && String === args[0] && args[0].to_i != 0
        load(*args)
      else
        hits = super
        # We need to save this so that the Rack Neo4j::Rails:LuceneConnection::Closer can close it
        Thread.current[:neo4j_lucene_connection] ||= []
        Thread.current[:neo4j_lucene_connection] << hits
        hits
      end
    end

    def load(*ids)
      result = ids.map { |id| Neo4j::Node.load(id) }
      if ids.length == 1
        result.first
      else
        result
      end
    end


    alias_method :_orig_create, :create

    def create(*)
      Neo4j::Rails::Transaction.running? ? create_in_tx(super) : Neo4j::Rails::Transaction.run { create_in_tx(super) }
    end

    def create!(*args)
      Neo4j::Rails::Transaction.running? ? create_in_tx!(_orig_create(*args)) : Neo4j::Rails::Transaction.run { create_in_tx!(_orig_create(*args)) }
    end

    def create_in_tx(model)
      model.save
      model
    end

    def create_in_tx!(model)
      model.save!
      model
    end

    def transaction(&block)
      Neo4j::Rails::Transaction.run &block
    end

    def accepts_nested_attributes_for(*attr_names)
      allow_destroy = if attr_names[-1].is_a?(Hash)
                        args = attr_names.pop
                        args[:allow_destroy]
                      end

      puts "ARGS = #{args}"
      attr_names.each do |association_name|
        rel = self._decl_rels[association_name.to_sym]
        raise "No relationship declared with has_n or has_one with type #{association_name}" unless rel
        to_class = rel.to_class
        raise "Can't use accepts_nested_attributes_for(#{association_name}) since it has not defined which class it has a relationship to, use has_n(#{association_name}).to(MyOtherClass)" unless to_class
        type = rel.namespace_type
        has_one = rel.has_one?

        class_eval <<-eoruby, __FILE__, __LINE__ + 1
              if method_defined?(:#{association_name}_attributes=)
                remove_method(:#{association_name}_attributes=)
              end
              def #{association_name}_attributes=(attributes)
                if #{has_one}
                  update_nested_attributes('#{type}', #{to_class}, nil, attributes)
                else
                  attributes.each_pair do |key, attr|
                    update_nested_attributes('#{type}', #{to_class}, key, attr)
                  end
                end
              end
        eoruby
      end
    end

  end

end

