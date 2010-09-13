module Neo4j::Mapping
  module PropertyClassMethods

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
    # The generated accessor is a simple wrapper around the #[] and
    # #[]= operators.
    #
    # If a property is set to nil the property will be removed.
    #
    # ==== Example
    #   class Baaz; end
    #
    #   class Foo
    #     include Neo4j::NodeMixin
    #     property :name, :city # can set several properties in one go
    #     property :bar
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


    def load
      # TODO
      node = db.graph.get_node_by_id(node_id.to_i)
      clazz = Neo4j::Node.to_class(node[:_classname])
      raise "Expected classname #{self} got #{clazz}" if clazz != self
    end

    def load_wrapper(node, db = Neo4j.db)
      wrapped_node = self.new
      wrapped_node.init_on_load(node)
      wrapped_node
    end


    # Creates a new node or loads an already existing Neo4j node.
    #
    # Does
    # * sets the neo4j property '_classname' to self.class.to_s
    # * creates a neo4j node java object (in @_java_node)
    # * calls init_node if that is defined in the current class.
    #
    # If you want to provide your own initialize method you should instead implement the
    # method init_node method.
    #
    # === Example
    #
    #   class MyNode
    #     include Neo4j::NodeMixin
    #
    #     def init_node(name, age)
    #        self[:name] = name
    #        self[:age] = age
    #     end
    #   end
    #
    #   node = MyNode.new('jimmy', 23)
    #   # notice the following is still possible:
    #   node = MyNode :name => 'jimmy', :age => 12
    #
    # The init_node is only called when the node is created in the database.
    # The initialize method is used both for to purposes:
    # loading an already existing node from the Neo4j database and creating a new node in the database.
    #
    def new(*args)
      node = Neo4j::Node.create
      wrapped_node = super()
      wrapped_node.init_on_load(node)
      wrapped_node.init_on_create(*args)
      wrapped_node
    end

    alias_method :create, :new

  end
end