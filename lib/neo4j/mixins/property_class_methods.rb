module Neo4j::PropertyClassMethods

  #
  # Access to class constants.
  # These properties are shared by the class and its siblings.
  # For example that means that we can specify properties for a parent
  # class and the child classes will 'inherit' those properties.
  #

  def root_class # :nodoc:
    self::ROOT_CLASS
  end

  def properties_info # :nodoc:
    self::PROPERTIES_INFO
  end


  # ------------------------------------------------------------------------


  # Generates accessor method and sets configuration for Neo4j node properties.
  # The generated accessor is a simple wrapper around the #set_property and
  # #get_property methods.
  #
  # If a property is set to nil the property will be removed.
  #
  # ==== Configuration
  # By setting the :type configuration parameter to 'Object' makes
  # it possible to marshal any ruby object.
  #
  # If no type is provided the only the native Neo4j property types are allowed:
  # * TrueClass, FalseClass
  # * String
  # * Fixnum
  # * Float
  # * Boolean
  #
  # ==== Parameters
  # props<Array,Hash>:: a variable length arguments or a hash, see example below
  #
  # ==== Example
  #   class Baaz; end
  #
  #   class Foo
  #     include Neo4j::NodeMixin
  #     property :name, :city # can set several properties in one go
  #     property :bar, :type => Object # allow serialization of any ruby object
  #   end
  #
  #   f = Foo.new
  #   f.bar = Baaz.new
  #
  def property(*props)
    if props.size == 2 and props[1].kind_of?(Hash)
      props[1].each_pair do |key, value|
        pname = props[0].to_sym
        properties_info[pname] ||= {}
        properties_info[pname][key] = value
      end
      props = props[0..0]
    end

    props.each do |prop|
      pname = prop.to_sym
      properties_info[pname] ||= {}
      properties_info[pname][:defined] = true

      define_method(pname) do
        self[pname]
      end

      name = (pname.to_s() +"=").to_sym
      define_method(name) do |value|
        self[pname] = value
      end
    end
  end

  # Returns true if the given property name should be marshalled.
  # All properties that has a type will be marshalled.
  #
  # ===== Example
  #   class Foo
  #     include Neo4j::NodeMixin
  #     property :name
  #     property :since, :type => Date
  #   end
  #   Foo.marshal?(:since) => true
  #   Foo.marshal?(:name) => false
  #
  # ==== Returns
  # true if the property will be marshalled, false otherwise
  #
  def marshal?(prop_name)
    return false if properties_info[prop_name.to_sym].nil?
    return false if properties_info[prop_name.to_sym][:type].nil?
    return true
  end


  # Returns true if the given property name has been defined with the class
  # method property or properties.
  #
  # Notice that the node may have properties that has not been declared.
  # It is always possible to set an undeclared property on a node.
  #
  # ==== Returns
  # true or false
  #
  def property?(prop_name)
    return false if properties_info[prop_name.to_sym].nil?
    properties_info[prop_name.to_sym][:defined] == true
  end


  # Creates a struct class containig all properties of this class.
  #
  # ==== Example
  #
  # h = Person.value_object.new
  # h.name    # => nil
  # h.name='kalle'
  # h[:name]   # => 'kalle'
  #
  # ==== Returns
  # Struct
  #
  def value_object
    @value_class ||= create_value_class
  end

  # Index a property or a relationship.
  # If the rel_prop arg contains a '.' then it will index the relationship.
  # For example "friends.name" will index each node with property name in the relationship friends.
  # For example "name" will index the name property of this NodeMixin class.
  #
  # ==== Example
  #   class Person
  #     include Neo4j::NodeMixin
  #     property :name
  #     index :name
  #   end
  #
  def index(*rel_type_props)
    if rel_type_props.size == 2 and rel_type_props[1].kind_of?(Hash)
      rel_type_props[1].each_pair do |key, value|
        idx = rel_type_props[0]
        indexer.field_infos[idx.to_sym][key] = value
      end
      rel_type_props = rel_type_props[0..0]
    end
    rel_type_props.each do |rel_type_prop|
      rel_name, prop = rel_type_prop.to_s.split('.')
      index_property(rel_name) if prop.nil?
      index_relationship(rel_name, prop) unless prop.nil?
    end
  end


  # Remove one or more specified indexes.
  # Those indexes will not be updated anymore, old indexes will still exist
  # until the update_index method is called.
  #
  def remove_index(*keys)
    keys.each do |key|
      raise "Not implemented remove index on a relationship index" if key.to_s.include?('.')
      indexer.remove_index_on_property(key)
    end
  end


  def index_property(prop) # :nodoc:
    indexer.add_index_on_property(prop)
  end


  def index_relationship(rel_name, prop) # :nodoc:
    # find the trigger and updater classes and the rel_type of the given rel_name
    trigger_clazz = decl_relationships[rel_name.to_sym].to_class
    trigger_clazz ||= self # if not defined in a has_n

    updater_clazz = self

    dsl = decl_relationships[rel_name.to_sym]
    rel_type = dsl.to_type # this or the other node we index ?
    rel_type ||= rel_name # if not defined (in a has_n) use the same name as the rel_name

    if dsl.outgoing?
      namespace_type = dsl.namespace_type
    else
      clazz = dsl.to_class || node.class
      namespace_type = clazz.decl_relationships[dsl.to_type].namespace_type
    end

    # add index on the trigger class and connect it to the updater_clazz
    # (a trigger may cause an update of the index using the Indexer specified on the updater class)
    trigger_clazz.indexer.add_index_in_relationship_on_property(updater_clazz, rel_name, rel_type, prop, namespace_type.to_sym)
  end


  # Finds all nodes or relationship of this type (and ancestors of this type) having
  # the specified property values.
  # See the lucene module for more information how to do a query.
  #
  # ==== Example
  #   MyNode.find(:name => 'foo', :company => 'bar')
  #
  # Or using a DSL query (experimental)
  #   MyNode.find{(name == 'foo') & (company == 'bar')}
  #
  # ==== Returns
  # Neo4j::SearchResult
  #
  def find(query=nil, &block)
    self.indexer.find(query, block)
  end
  

  # Creates a new value object class (a Struct) representing this class.
  #
  # The struct will have the Ruby on Rails method: model_name and
  # new_record? so that it can be used for restful routing.
  #
  def create_value_class # :nodoc:
    # the name of the class we want to create
    name = "#{self.to_s}ValueObject".gsub("::", '_')

    # remove previous class if exists
    Neo4j.instance_eval do
      remove_const name
    end if Neo4j.const_defined?(name)

    # get the properties we want in the new class
    props = self.properties_info.keys.map{|k| ":#{k}"}.join(',')
    Neo4j.module_eval %Q[class #{name} < Struct.new(#{props}); end]

    # get reference to the new class
    clazz = Neo4j.const_get(name)

    # make it more Ruby on Rails friendly - try adding model_name method
    if self.respond_to?(:model_name)
      model = self.model_name.clone
      (
      class << clazz;
        self;
      end).instance_eval do
        define_method(:model_name) {model}
      end
    end

    # by calling the _update method we change the state of the struct
    # so that new_record returns false - Ruby on Rails
    clazz.instance_eval do
      define_method(:_update) do |hash|
        @_updated = true
        hash.each_pair {|key, value| self[key.to_sym] = value if members.include?(key.to_s) }
      end
      define_method(:new_record?) { ! defined?(@_updated) }
    end

    clazz
  end
  
end
