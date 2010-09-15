class Neo4j::ActiveModel

  include Neo4j::NodeMixin
  extend ActiveModel::Naming
  include ActiveModel::Validations
  include ActiveModel::Dirty
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
    _run_create_callbacks do
      @_new_record = true
      super
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


  # --------------------------------------
  # enables ActiveModel::Dirty and Validation
  # --------------------------------------

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

  def attributes=(attrs)
    attrs.each do |k, v|
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
    update(attributes) # TODO !!!
    save
  end

  # --------------------------------------
  # CRUD
  # --------------------------------------

  def delete
    super
    @_deleted = true
  end

  def save
    if valid?
      # if we are trying to save a value then we should create a real node
      if persisted?
        _run_update_callbacks do
          @previously_changed = changes
          @changed_attributes.clear
        end
      else
        node = Neo4j::Node.new(props)
        init_on_load(node)
        init_on_create
        @previously_changed = changes
        @changed_attributes.clear
      end
      true
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
    @_new_record
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


  # --------------------------------------
  # Class Methods
  # --------------------------------------

  class << self
    # returns a value object instead of creating a new node
    def new(*args)
      value = Neo4j::Value.new(*args)
      wrapped = self.orig_new
      wrapped.init_on_load(value)
      wrapped
    end


    # Handle Model.find(params[:id])
    def find(*args)
      if args.length == 1 && String === args[0] && args[0].to_i != 0
        load(*args)
      else
        super
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

    def create!(*args)
      model = create(*args)
      raise RecordInvalidError.new(model) unless model.valid?
      model
    end
  end

end
