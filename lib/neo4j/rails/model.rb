class Neo4j::Model
  include Neo4j::NodeMixin
  include ActiveModel::Validations
  include ActiveModel::Dirty
  include ActiveModel::MassAssignmentSecurity

  extend ActiveModel::Naming
  extend ActiveModel::Callbacks
  extend Neo4j::Validations::ClassMethods
  extend Neo4j::TxMethods

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
  # If saving fails because the resource is invalid then false will be returned.
  def update_attributes(attributes)
    self.attributes=attributes
    save
  end

  def update_attributes!(attributes)
    self.attributes=attributes
    save!
  end

  def update_nested_attributes(rel_type, clazz, has_one, attr, options)
    allow_destroy,reject_if = [options[:allow_destroy], options[:reject_if]] if options

    if new?
      # We are updating a node that was created with the 'new' method.
      # The relationship will only be kept in the Value object.
      outgoing(rel_type)<<clazz.new(attr) unless reject_if?(reject_if,attr)
    else
      # We have a node that was created with the #create method - has real Neo4j relationships
      # does it exist ?
      found = if has_one
                # id == nil that means we have a has_one relationship
                outgoing(rel_type).first
              else
                # do we have an ID ?
                id = attr[:id]
                # this is a has_n relationship, find which one we want to update
                id && outgoing(rel_type).find { |n| n.id == id }
              end

      # Check if we want to destroy not found nodes (e.g. {..., :_destroy => '1' } ?
      destroy = attr[:_destroy] && attr[:_destroy] != '0'

      if found
        if destroy
          found.destroy if allow_destroy
        else
          found.update_attributes_in_tx(attr) # it already exist, so update that one
        end
      elsif !destroy && !reject_if?(reject_if,attr)
        new_node = clazz.new(attr)
        saved = new_node.save
        outgoing(rel_type) << new_node if saved
      end
    end
  end

  def reject_if?(proc_or_symbol, attr)
    return false if proc_or_symbol.nil?
    if proc_or_symbol.is_a?(Symbol)
      meth = method(proc_or_symbol)
      meth.arity == 0 ? meth.call : meth.call(attr)
    else
      proc_or_symbol.call(attr)
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
      valid = _run_save_callbacks { create_or_update_node }
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

  def create_or_update_node
    valid = true
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
    _run_update_callbacks { del }
  end

  def destroyed?()
    @_deleted
  end

  tx_methods :destroy, :create_or_update_node, :update_attributes, :update_attributes!

  # --------------------------------------
  # Class Methods
  # --------------------------------------

  class << self
    extend Neo4j::TxMethods

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
            raise "NOT IMPLEMENTED #{field} (incoming relationship) FOR #new method, please create a new model with the create method instead"
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
      model = super
      model.save
      model
    end

    def create!(*args)
      model = _orig_create(*args)
      model.save!
      model
    end

    tx_methods :create, :create!


    def transaction(&block)
      Neo4j::Rails::Transaction.run &block
    end

    def accepts_nested_attributes_for(*attr_names)
      options = attr_names.pop if attr_names[-1].is_a?(Hash)

      attr_names.each do |association_name|
        rel = self._decl_rels[association_name.to_sym]
        raise "No relationship declared with has_n or has_one with type #{association_name}" unless rel
        to_class = rel.to_class
        raise "Can't use accepts_nested_attributes_for(#{association_name}) since it has not defined which class it has a relationship to, use has_n(#{association_name}).to(MyOtherClass)" unless to_class
        type = rel.namespace_type
        has_one = rel.has_one?

        send(:define_method, "#{association_name}_attributes=") do |attributes|
          if has_one
            update_nested_attributes(type, to_class, true, attributes, options)
          else
            if attributes.is_a?(Array)
              attributes.each do |attr|
                update_nested_attributes(type, to_class, false, attr, options)
              end
            else
              attributes.each_value do |attr|
                update_nested_attributes(type, to_class, false, attr, options)
              end
            end
          end
        end
        tx_methods("#{association_name}_attributes=")
      end
    end

  end

end

