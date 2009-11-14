module Neo4j


  class LuceneIndexOutOfSyncException < StandardError

  end


  #
  # Represents a node in the Neo4j space.
  # 
  # Is a wrapper around a Java neo node
  # 
  #
  module NodeMixin
    attr_reader :internal_node

    extend TransactionalMixin

    # --------------------------------------------------------------------------
    # Initialization methods
    #


    # Initialize the the neo node for this instance.
    # Will create a new transaction if one is not already running.
    # 
    # Does
    # * sets the neo property 'classname' to self.class.to_s
    # * creates a neo node java object (in @internal_node)
    # * calls init_node if that is defined in the current class.
    #
    # :api: public
    def initialize(*args)
      # was a neo java node provided ?
      if args.length == 1 and args[0].kind_of?(org.neo4j.api.core.Node)
        init_with_node(args[0])
      else
        init_without_node
        init_node(*args) if self.respond_to?(:init_node)
      end
      yield self if block_given?
      # must call super with no arguments so that chaining of the initialize method works
      super()
    end


    # Inits this node with the specified java neo node
    #
    # :api: private
    def init_with_node(node)
      @internal_node = node
    end

    # Inits when no neo java node exists. Must create a new neo java node first.
    #
    # :api: private
    def init_without_node
      @internal_node = Neo4j.instance.create_node
      self.classname = self.class.to_s
      Neo4j.event_handler.node_created(self)
    end


    # --------------------------------------------------------------------------
    # Property methods
    #

    # Sets a neo property on this node. This property does not have to be declared first.
    # If the value of the property is nil the property will be removed.
    #
    # ==== Parameters
    # name<String>:: the name of the property to be set
    # value<Object>:: the value of the property to be set.
    #
    # ==== Example
    #   n = Node.new
    #   n.foo = 'hej'
    # 
    # :api: public
    def set_property(name, value)
      return if name.to_s == 'id' # id is neo_node_id and cannot be changed TODO check this
      old_value = get_property(name)

      if value.nil?
        remove_property(name)
      elsif self.class.marshal?(name)
        @internal_node.set_property(name, Marshal.dump(value).to_java_bytes)
      else
        # in JRuby 1.2.0 it converts a Float incorrectly to a java.lang.float
        value = java.lang.Double.new(value) if value.is_a? Float
        @internal_node.set_property(name, value)
      end

      if (name != 'classname') # do not want events on internal properties
        self.class.indexer.on_property_changed(self, name) # TODO reuse the event_handler instead !
        Neo4j.event_handler.property_changed(self, name, old_value, value)
      end
    end


    # Sets the given property to a given value.
    # Same as Neo4j::NodeMixin#set_property
    #
    # :api: public
    def []=(name, value)
      set_property(name.to_s, value)
    end

    # Removes the property from this node.
    # For more information see JavaDoc PropertyContainer#removeProperty
    #
    # ==== Example
    #   a = Node.new
    #   a.set_property('foo',2)
    #   a.remove_property('foo')
    #   a.get_property('foo') # => nil
    #
    # ==== Returns
    # true if the property was removed, false otherwise
    #
    # :api: public
    def remove_property(name)
      removed = !@internal_node.removeProperty(name).nil?
      self.class.indexer.on_property_changed(self, name) if removed
      removed
    end


    # Returns the value of the given neo property.
    #
    # ==== Returns
    # the value of the property or nil if the property does not exist
    #
    # :api: public
    def get_property(name)
      return nil if ! property?(name)
      value = @internal_node.get_property(name.to_s)
      if self.class.marshal?(name)
        Marshal.load(String.from_java_bytes(value))
      else
        value
      end
    end


    # Returns the given property
    #
    # :api: public
    def [](name)
      self.get_property(name.to_s)
    end

    # Checks if the given neo property exists.
    #
    # ==== Returns
    # true if the property exists
    #
    # :api: public
    def property?(name)
      @internal_node.has_property(name.to_s) unless @internal_node.nil?
    end


    # Creates a struct class containing all properties of this class.
    # This value object can be used from Ruby on Rails RESTful routing.
    #
    # ==== Example
    #
    # h = Person.value_object.new
    # h.name    # => nil
    # h.name='kalle'
    # h[:name]   # => 'kalle'
    #
    # ==== Returns
    # a value object struct
    #
    # :api: public
    def value_object
      vo = self.class.value_object.new
      vo._update(props)
      vo
    end

    # Returns an unique id
    # Calls getId on the neo node java object
    #
    # ==== Returns
    # Fixnum:: the unique neo id of the node.
    #
    # :api: public
    def neo_node_id
      @internal_node.getId()
    end


    # Same as neo_node_id but returns a String instead of a Fixnum.
    # Used by Ruby on Rails.
    #
    # :api: public
    def to_param
      neo_node_id.to_s
    end

    # Returns a hash of all properties.
    #
    # ==== Returns
    # Hash:: property key and property value
    #
    # :api: public
    def props
      ret = {"id" => neo_node_id}
      iter = @internal_node.getPropertyKeys.iterator
      while (iter.hasNext) do
        key = iter.next
        ret[key] = @internal_node.getProperty(key)
      end
      ret
    end


    # --------------------------------------------------------------------------
    # Equal and hash methods
    #

    def eql?(o)
      o.kind_of?(NodeMixin) && o.internal_node == internal_node
    end

    def ==(o)
      eql?(o)
    end

    def hash
      internal_node.hashCode
    end


    # --------------------------------------------------------------------------
    # Update and Delete methods
    #


    # Updates this node's properties by using the provided struct/hash.
    # If the option <code>{:strict => true}</code> is given, any properties present on
    # the node but not present in the hash will be removed from the node.
    #
    # ==== Parameters
    # struct_or_hash<#each_pair>:: the key and value to be set
    # options<Hash>:: further options defining the context of the update
    #
    # ==== Returns
    # self
    #
    # :api: public
    def update(struct_or_hash, options={})
      strict = options[:strict]
      keys_to_delete = props.keys - %w(id classname) if strict
      struct_or_hash.each_pair do |key, value|
        next if %w(id classname).include? key.to_s # do not allow special properties to be mass assigned
        keys_to_delete.delete(key) if strict
        self[key] = value
      end
      keys_to_delete.each{|key| remove_property(key) } if strict
      self
    end


    # Deletes this node.
    # Invoking any methods on this node after delete() has returned is invalid and may lead to unspecified behavior.
    #
    # :api: public
    def delete
      Neo4j.event_handler.node_deleted(self)

      # delete outgoing relationships, and check for cascade delete
      relationships.outgoing.each { |r| r.delete; r.end_node.delete if r[:_cascade_delete_outgoing]}

      relationships.incoming.each do |r|
        r.delete
        if r[:_cascade_delete_incoming]
          node_id = r[:_cascade_delete_incoming]
          node = Neo4j.load(node_id)
          # check node has no outgoing relationships
          no_outgoing = node.relationships.outgoing.empty?
          # check node has only incoming relationship with cascade_delete_incoming
          no_incoming = node.relationships.incoming.find{|r| !node.ignore_incoming_cascade_delete?(r)}.nil?
          # only cascade delete incoming if no outgoing and no incoming (exception cascade_delete_incoming) relationships
          node.delete if no_outgoing and no_incoming
        end
      end
      @internal_node.delete
      self.class.indexer.delete_index(self)
    end


    # Specifies which relationships should be ignored when trying to cascade delete a node.
    # If a node does not have any relationships (except those specified here to ignore) it will be cascade deleted
    #
    def ignore_incoming_cascade_delete?(relationship)
      # ignore relationship with property _cascade_delete_incoming
      relationship.property?(:_cascade_delete_incoming)
    end

    # Updates the index for this node.
    # This method will be automatically called when needed
    # (a property changed or a relationship was created/deleted)
    #
    # @api private
    def update_index
      self.class.indexer.index(self)
    end

    # --------------------------------------------------------------------------
    # Relationship methods
    #

    # Returns a Neo4j::Relationships::RelationshipTraverser object for accessing relationships from and to this node.
    # The Neo4j::Relationships::RelationshipTraverser is an Enumerable that returns Neo4j::RelationshipMixin objects.
    #
    # ==== Returns
    # A Neo4j::Relationships::RelationshipTraverser object
    #
    # ==== See Also
    # * Neo4j::Relationships::RelationshipTraverser
    # * Neo4j::RelationshipMixin
    #
    # ==== Example
    #
    #   person_node.relationships.outgoing(:friends).each { ... }
    #
    # :api: public
    def relationships(direction = :outgoing)
      Relationships::RelationshipTraverser.new(self, direction)
    end


    # Returns a single relationship or nil if none available.
    # If there are more then one relationship of the given type it will raise an exception.
    #
    # ==== Parameters
    # type<#to_s>:: the key and value to be set
    # dir:: optional default :outgoing (either, :outgoing, :incoming, :both)
    #
    # ==== Returns
    # An object that mixins the Neo4j::RelationshipMixin representing the given relationship type or nil if there are no relationships.
    # If there are more then one relationship it will raise an Exception (java exception of type org.neo4j.api.core.NotFoundException)
    #
    # ==== See Also
    # * JavaDoc for http://api.neo4j.org/current/org/neo4j/api/core/Node.html#getSingleRelationship(org.neo4j.api.core.RelationshipType,%20org.neo4j.api.core.Direction)
    # * Neo4j::RelationshipMixin
    #
    # ==== Example
    #
    #   person_node.relationship(:address).end_node[:street]
    #
    # :api: public
    def relationship(rel_name, dir=:outgoing)
      java_dir = _to_java_direction(dir)
      rel_type = Relationships::RelationshipType.instance(rel_name)
      rel = @internal_node.getSingleRelationship(rel_type, java_dir)
      return nil if rel.nil?
      Neo4j.load_relationship(rel.getId)
    end

    # Check if the given relationship exists
    # Returns true if there are one or more relationships from this node to other nodes
    # with the given relationship.
    # It will not return true only because the relationship is defined.
    #
    # ==== Parameters
    # rel_name<#to_s>:: the key and value to be set
    # dir:: optional default :outgoing (either, :outgoing, :incoming, :both)
    #
    # ==== Returns
    # true if one or more relationships exists for the given rel_name and dir
    # otherwise false
    #
    # :api: public
    def relationship?(rel_name, dir=:outgoing)
      type = Relationships::RelationshipType.instance(rel_name.to_s)
      java_dir = _to_java_direction(dir)
      @internal_node.hasRelationship(type, java_dir)
    end


    # Returns a Neo4j::Relationships::NodeTraverser object for traversing nodes from and to this node.
    # The Neo4j::Relationships::NodeTraverser is an Enumerable that returns Neo4j::NodeMixin objects.
    #
    # ==== See Also
    # Neo4j::Relationships::NodeTraverser
    #
    # ==== Example
    #
    #   person_node.traverse.outgoing(:friends).each { ... }
    #
    # :api: public
    def traverse
      Relationships::NodeTraverser.new(@internal_node)
    end


    # --------------------------------------------------------------------------
    # List methods
    #


    # Returns true if this nodes belongs to a list of the given name
    #
    def list?(list_name)
      regexp = Regexp.new "_list_#{list_name}"
      relationships.both.find { |rel| regexp.match(rel.relationship_type.to_s) } != nil
    end

    # Returns one or more list of the given list_name and list_node.
    # If the optional list_node parameter is given the specific list belonging to that list node will be returned (or nil)
    # If only the list_name parameter is given the first list matching the given list_name will be returned.
    # (There might be several list of the same name but from different list nodes.)
    #
    # ==== Returns
    #
    # The node but with the extra instance methods
    # * next - the next node in the list
    # * prev - the previous node in the list
    # * head - the head node (the node that has the has_list method)
    # * size (if the size optional parameter is given in the has_list class method)
    #
    # ==== Example
    #  class Foo
    #    include Neo4j::NodeMixin
    #    has_list :baar
    #  end
    #
    #  f = Foo.new
    #  n1 = Neo4j::Node.new
    #  n2 = Neo4j::Node.new
    #  f.baar << n1 << n2
    #
    #  n2.list(:baar).next # => n1
    #  n2.list(:baar).prev # => f
    #  n2.list(:baar).head # => f
    #
    def list(list_name, list_node = nil)
      if list_node
        list_id = "_list_#{list_name}_#{list_node.neo_node_id}"
        add_list_item_methods(list_id, list_name, list_node)
      else
        list_items = []
        lists(list_name) {|list_item| list_items << list_item}
        list_items[0]
      end
    end


    # Returns an array of lists with the given names that this nodes belongs to.
    # Expects a block to yield for each found list
    # That block will be given one parameter - the node with the extra method (see #list method)
    #
    def lists(*list_names)
      list_names.collect! {|n| n.to_sym}

      relationships.both.inject({}) do |res, rel|
        rel_type = rel.relationship_type.to_s
        md = /_list_(\w*)_(\d*)/.match(rel_type)
        next res if md.nil?
        next res unless list_names.empty? || list_names.include?(md[1].to_sym)
        res[rel_type] = [md[1], Neo4j.load(md[2].to_i)]
        res
      end.each_pair do |rel_id, list_name_and_head_node|
        yield self.clone.add_list_item_methods(rel_id, list_name_and_head_node[0], list_name_and_head_node[1])
      end
    end


    def add_list_item_methods(list_id, list_name, head_node) #:no_doc:
      mod = Module.new do
        define_method :head do
          head_node
        end

        define_method :size do
          head_node["_#{list_name}_size"] || 0
        end

        define_method :size= do |new_size|
          head_node["_#{list_name}_size"] = new_size
        end

        define_method :next do
          next_node = relationships.outgoing(list_id).nodes.first
          return nil if next_node.nil?
          next_node.add_list_item_methods(list_id, list_name, head_node)
          next_node
        end

        define_method :next= do |new_next|
          # does it have a next pointer ?
          next_rel = relationships.outgoing(list_id).first
          # delete the relationship if exists
          next_rel.delete if (next_rel.nil?)
          relationships.outgoing(list_id) << new_next unless new_next.nil?
          nil
        end

        define_method :prev do
          prev_node = relationships.incoming(list_id).nodes.first
          return nil if prev_node.nil?
          prev_node.add_list_item_methods(list_id, list_name, head_node)
          prev_node
        end

        define_method :prev= do |new_prev|
          # does it have a next pointer ?
          prev_rel = relationships.incoming(list_id).first
          # delete the relationship if exists
          prev_rel.delete if (prev_rel.nil?)
          relationships.outgoing(list_id) << new_prev unless new_prev.nil?
          nil
        end
      end

      self.extend mod
    end

    def add_list_head_methods(list_name) # :nodoc:
      prop_name = "_#{list_name}_size".to_sym
      mod = Module.new do
        define_method :size do
          self[prop_name] || 0
        end

        define_method :size= do |new_size|
          self[prop_name]=new_size
        end
      end
      self.extend mod
    end

    # --------------------------------------------------------------------------
    # Debug
    #

    def print(levels = 0, dir = :outgoing)
      print_sub(0, levels, dir)
    end

    def print_sub(level, max_level, dir)
      spaces = " " * level
      node_desc = "#{spaces}#{classname} id=#{neo_node_id}"
      props.each_pair {|key, value| next if %w[classname id].include?(key); node_desc << " #{key}='#{value}'"}
      puts node_desc

      if (level != max_level)
        relationships(dir).each do |rel|
          cascade_desc = ""
          cascade_desc << "cascade in: #{rel[:_cascade_delete_incoming]}" if rel.property?(:_cascade_delete_incoming)
          cascade_desc << "cascade out: #{rel[:_cascade_delete_outgoing]}" if rel.property?(:_cascade_delete_outgoing)
          puts "#{spaces}rel dir: #{dir} type: '#{rel.relationship_type}' id: #{rel.neo_relationship_id} #{cascade_desc}"
          rel.other_node(self).print_sub(level + 1, max_level, dir)
        end
      end
    end


    # --------------------------------------------------------------------------
    # Private methods
    #

    # :api: private
    def _to_java_direction(dir) # :nodoc:
      case dir
        when :outgoing
          org.neo4j.api.core.Direction::OUTGOING
        when :incoming
          org.neo4j.api.core.Direction::INCOMING
        when :both
          org.neo4j.api.core.Direction::BOTH
        else
          raise "Unknown parameter: '#{dir}', only accept :outgoing, :incoming or :both"
      end
    end

    # all creation of relationships uses this method
    # triggers event handling
    # :api: private
    def _create_relationship(type, to) # :nodoc:
      java_type = Relationships::RelationshipType.instance(type)
      java_relationship = internal_node.createRelationshipTo(to.internal_node, java_type)

      relationship =
              if (self.class.relationships_info[type.to_sym].nil?)
                Relationships::Relationship.new(java_relationship)
              else
                self.class.relationships_info[type.to_sym][:relationship].new(java_relationship)
              end
      Neo4j.event_handler.relationship_created(relationship)
      self.class.indexer.on_relationship_created(self, type)
      relationship
    end


    # :api: private
    def classname # :nodoc:
      get_property('classname')
    end

    # :api: private
    def classname=(value) # :nodoc:
      set_property('classname', value)
    end


    # --------------------------------------------------------------------------
    # Transactional methods declaration
    #

    transactional :initialize, :property?, :set_property, :get_property, :remove_property, :delete


    # --------------------------------------------------------------------------
    # Hooks
    #


    # Adds class methods in the ClassMethods module
    #
    def self.included(c) # :nodoc:
      # all subclasses share the same index, declared properties and index_updaters
      c.instance_eval do
        const_set(:ROOT_CLASS, self)
        const_set(:RELATIONSHIPS_INFO, {})
        const_set(:PROPERTIES_INFO, {})
      end unless c.const_defined?(:ROOT_CLASS)

      c.extend ClassMethods
    end

    # --------------------------------------------------------------------------
    # NodeMixin class methods
    #
    module ClassMethods

      #
      # Access to class constants.
      # These properties are shared by the class and its siblings.
      # For example that means that we can specify properties for a parent
      # class and the child classes will 'inherit' those properties.
      #

      # :api: private
      def root_class
        self::ROOT_CLASS
      end

      def indexer
        Indexer.instance(root_class)
      end


      # Contains information of all relationships, name, type, and multiplicity
      #
      # :api: private
      def relationships_info
        self::RELATIONSHIPS_INFO
      end

      # :api: private
      def properties_info
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
      #     property name, city # can set several properties in one go
      #     property bar, :type => Object # allow serialization of any ruby object
      #   end
      #
      #   f = Foo.new
      #   f.bar = Baaz.new
      #
      # :api: public
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
            get_property(pname.to_s)
          end

          name = (pname.to_s() +"=").to_sym
          define_method(name) do |value|
            set_property(pname.to_s, value)
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
      # :api: public
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
      # :api: public
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
      # :api: public
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
      # :api: public
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


      # Remote one or more specified indexes.
      # This indexes will not be updated anymore, old indexes will still exist
      # until the update_index method is called.
      #
      # :api: public
      def remove_index(*keys)
        keys.each do |key|
          rel_name, prop = key.to_s.split('.')
          if prop.nil?
            indexer.remove_index_on_property(rel_name)
          else
            clazz, rel_type = rel_class_and_type_for(rel_name)
            clazz.indexer.remove_index_in_relationship_on_property(rel_type, prop)
          end
        end
      end


      # :api: private
      def index_property(prop)
        indexer.add_index_on_property(prop)
      end


      # :api: private
      def index_relationship(rel_name, prop)
        # find the trigger and updater classes and the rel_type of the given rel_name
        trigger_clazz = relationships_info[rel_name.to_sym][:class]
        trigger_clazz ||= self # if not defined in a has_n

        updater_clazz = self

        rel_type = relationships_info[rel_name.to_sym][:type] # this or the other node we index ?
        rel_type ||= rel_name # if not defined (in a has_n) use the same name as the rel_name

        # add index on the trigger class and connect it to the updater_clazz
        # (a trigger may cause an update of the index using the Indexer specified on the updater class)
        trigger_clazz.indexer.add_index_in_relationship_on_property(updater_clazz, rel_name, rel_type, prop)
      end


      # Specifies a relationship between two node classes.
      #
      # ==== Example
      #   class Order
      #      has_one(:customer).of_class(Customer)
      #   end
      #
      # :api: public
      def has_one(rel_type, params = {})
        cascade_delete = cascade_delete_param(params)
        module_eval(%Q{def #{rel_type}=(value)
                        r = Relationships::HasN.new(self,'#{rel_type.to_s}', #{cascade_delete})
                        r << value
                        r
                    end},  __FILE__, __LINE__)

        module_eval(%Q{def #{rel_type}
                        r = Relationships::HasN.new(self,'#{rel_type.to_s}', #{cascade_delete})
                        r.to_a[0]
                    end},  __FILE__, __LINE__)
        relationships_info[rel_type] = Relationships::RelationshipInfo.new
      end


      # Specifies a relationship between two node classes.
      #
      # ==== Example
      #   class Order
      #      has_n(:order_lines).to(Product).relationship(OrderLine)
      #   end
      #
      # :api: public
      def has_n(rel_type, params = {})
        cascade_delete = cascade_delete_param(params)
        module_eval(%Q{
                    def #{rel_type}(&block)
                        Relationships::HasN.new(self,'#{rel_type.to_s}', #{cascade_delete}, &block)
                    end},  __FILE__, __LINE__)
        relationships_info[rel_type] = Relationships::RelationshipInfo.new
      end

      def cascade_delete_param(params)
        cascade_delete = case params[:cascade_delete]
          when nil
            "nil"
          when :outgoing
            ":_cascade_delete_outgoing"
          when :incoming
            ":_cascade_delete_incoming"
          else
            raise "Expected either :outgoing or :incoming cascade delete parameter for has list"
        end
        return cascade_delete
      end

      # Specifies a relationship to a linked list of nodes.
      # Each list item class may (but not necessarily  use the belongs_to_list
      # in order to specify which ruby class should be loaded when a list item is loaded.
      #
      # Example
      #
      #  class Company
      #    has_list :employees
      #  end
      #
      #  company = Company.new
      #  company.employees << employee1 << employee2
      #
      #  # prints first employee2 and then employee1
      #  company.employees.each {|employee| puts employee.name}
      #
      # ===== Size Counter
      # If the optional parameter :size is given then the list will contain a size counter.
      #
      # Example
      #
      #  class Company
      #    has_list :employees, :counter => true
      #  end
      #
      #  company = Company.new
      #  company.employees << employee1 << employee2
      #  company.employees.size # => 2
      #
      # ==== Deleted List Items
      #
      # The list will be updated if an item is deleted in a list.
      # Example:
      #
      #  company = Company.new
      #  company.employees << employee1 << employee2 << employee3
      #  company.employees.size # => 3
      #
      #  employee2.delete
      #
      #  company.employees.to_a # => [employee1, employee3]
      #  company.employees.size # => 2
      #
      # ===== List Items Memberships
      #
      #  For deciding which lists a node belongs to see the Neo4j::NodeMixin#list method
      #
      # :api: public
      def has_list(rel_type, params = {})
        counter = params[:counter] == true
        cascade_delete = cascade_delete_param(params)
        module_eval(%Q{
                    def #{rel_type}(&block)
                        Relationships::HasList.new(self,'#{rel_type.to_s}',#{counter},#{cascade_delete}, &block)
                    end},  __FILE__, __LINE__)
        Neo4j.event_handler.add Relationships::HasList
        relationships_info[rel_type] = Relationships::RelationshipInfo.new
      end


      # Can be used together with the has_list to specify the ruby class of a list item.
      #
      # :api: public
      def belongs_to_list(rel_type)
        relationships_info[rel_type] = Relationships::RelationshipInfo.new
      end


      # Creates a new outgoing relationship.
      #
      # :api: private
      def new_relationship(rel_name, internal_relationship)
        relationships_info[rel_name.to_sym][:relationship].new(internal_relationship) # internal_relationship is a java neo object
      end


      # Finds all nodes of this type (and ancestors of this type) having
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
      # :api: public
      def find(query=nil, &block)
        self.indexer.find(query, block)
      end


      # Creates a new value object class (a Struct) representing this class.
      #
      # The struct will have the Ruby on Rails method: model_name and
      # new_record? so that it can be used for restful routing.
      #
      # @api private
      def create_value_class
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
  end
end
