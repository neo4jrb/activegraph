class Neo4j::Model
  include Neo4j::NodeMixin
  include ActiveModel::Validations
  include ActiveModel::Dirty
  include ActiveModel::MassAssignmentSecurity
  extend ActiveModel::Naming
  extend ActiveModel::Callbacks
  define_model_callbacks :create, :save, :update, :destroy

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
    if Neo4j::Rails::Transaction.running?
      super()
      init_on_create_in_tx(*args)
    else
      Neo4j::Rails::Transaction.run { super(); init_on_create_in_tx(*args) }
    end
  end

  def init_on_create_in_tx(*args)
    _run_save_callbacks do
      _run_create_callbacks do
        self.attributes=args[0] if args[0].respond_to?(:each_pair)
      end
    end
  end
  # --------------------------------------
  # Identity
  # --------------------------------------

  def id
    self.neo_id
  end

  def to_param
    persisted? ?  neo_id.to_s : nil
  end

  # Returns an Enumerable of all (primary) key attributes
  # or nil if model.persisted? is false
  def to_key
    persisted? ?  [:id] : nil
  end


  # enables ActiveModel::Dirty and Validation
  def method_missing(method_id, *args, &block)
    if !self.class.attribute_methods_generated?
      self.class.define_attribute_methods(self.class.properties_info.keys)
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
      #changed_attributes[key] = new_value unless old_value == new_value
    end
    super
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
    self[key]
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
    Neo4j::Rails::Transaction.running? ? update_attributes_in_tx(attributes): Neo4j::Rails::Transaction.run { update_attributes_in_tx(attributes) }
  end

  def update_attributes_in_tx(attributes)
    self.attributes=attributes
    save
  end

  def update_attributes!(attributes)
    Neo4j::Rails::Transaction.running? ? update_attributes_in_tx!(attributes): Neo4j::Rails::Transaction.run { update_attributes_in_tx!(attributes) }
  end

  def update_attributes_in_tx!(attributes)
    self.attributes=attributes
    save!
  end

  def delete
    super
    @_deleted = true
  end

  def save
    if valid?
      # if we are trying to save a value then we should create a real node
      Neo4j::Rails::Transaction.running? ? save_in_tx : Neo4j::Rails::Transaction.run { save_in_tx }
      true
    else
      # if not valid we should rollback the transaction if there is one
      # so that the changes does not take place.
      # no point failing the transaction if we have not already persisted it since it will then
      # not be persisted
      Neo4j::Rails::Transaction.fail if Neo4j::Rails::Transaction.running? && persisted?
      false
    end
  end

  def save_in_tx
    if persisted?
      # already existing node - so we are updating it
      _run_update_callbacks do
        @previously_changed = changes
        @changed_attributes.clear
      end
    else
      # we are creating a new node
      node = Neo4j::Node.new(props)
      init_on_load(node)
      init_on_create
      @previously_changed = changes
      @changed_attributes.clear
    end

  end

  def save!
  raise RecordInvalidError.new(self) unless save
  end

  # In neo4j all object are automatically persisted in the database when created (but the Transaction might get rollback)
  # Only the Neo4j::Value object will never exist in the database
  def persisted?
    !_java_node.kind_of?(Neo4j::Value)
  end

  def to_model
    self
  end

  def new_record?()
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

    def create(*)
      Neo4j::Rails::Transaction.running? ? super : Neo4j::Rails::Transaction.run { super }
    end

    def create!(*args)
      model = create(*args)
      raise RecordInvalidError.new(model) unless model.valid?
      model
    end

    def transaction(&block)
      Neo4j::Rails::Transaction.run &block
    end
  end

end
