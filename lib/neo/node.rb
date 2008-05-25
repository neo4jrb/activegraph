require 'neo/relations'

module Neo

  #
  # Represent a node in the Neo space.
  # 
  # Is a wrapper around a Java neo node
  # 
  #
  module Node
    attr_reader :internal_node 
    
    #
    # Must be run in an transaction unless a block is given 
    # If a block is given a new transaction will be created
    # 
    # Does
    # * sets the neo property 'classname' to self.class.to_s
    # * creates a neo node java object (in @internal_node)
    # * creates a relationship in the metanode instance to this instance
    #    
    def initialize(*args)
      if args.length == 1 and args[0].kind_of?(org.neo4j.api.core.Node)
        @internal_node = args[0]
        self.classname = self.class.to_s unless @internal_node.hasProperty("classname")
        $neo_logger.debug {"created '#{self.class.to_s}' using provided java neo node id #{@internal_node.getId()}"}
      elsif block_given? # check if we should run in a transaction
        Neo::transaction { create_internal_node; yield self }
        $neo_logger.debug {"created '#{self.class.to_s}' with a new transaction"}        
      else
        create_internal_node
        $neo_logger.debug {"created '#{self.class.to_s}' without a new transaction"}                
      end
      
      super()
    end
    
    def create_internal_node
      @internal_node = Neo::neo_service.create_node
      self.classname = self.class.to_s
      update_meta_node_instances self.class
    end
    
    def update_meta_node_instances(clazz)
      meta_node = clazz.meta_node
      # $neo_logger.warn("No meta_node for #{self} type #{self.class.to_s}") if meta_node.nil?
      return if meta_node.nil?
      
      # add the instance to the list of instances in the meta node      
      # self.class.meta_node.nil might be nil since it could be a MetaNode
      meta_node.instances << self
      
      # TODO add to ancestors as well
      clazz.ancestors.each do |a|
        next if a == clazz 
        next unless a.respond_to?(:meta_node)
        update_meta_node_instances a
      end
    end

    def method_missing(methodname, *args)
      # allows to set and get any neo property without declaring them first
      name = methodname.to_s
      setter = /=$/ === name
      expected_args = 0
      if setter
        name = name[0...-1]
        expected_args = 1
      end
      unless args.size == expected_args
        err = "method '#{name}' on '#{self.class.to_s}' has wrong number of arguments (#{args.size} for #{expected_args})"
        raise ArgumentError.new(err)
      end

      raise Exception.new("Node not initialized, called method '#{methodname}' on #{self.class.to_s}") unless @internal_node
      
      if setter
        @internal_node.set_property(name, args[0])
      else
        if !@internal_node.has_property(name)
          super.method_missing(methodname, *args)
        else        
          @internal_node.get_property(name)
        end      
      end
    end
    
    
    # 
    # Returns a unique id
    # Calls getId on the neo node java object
    #
    def neo_node_id
      @internal_node.getId()
    end

    def eql?(o)    
      o.is_a?(self.class) && o.internal_node == internal_node
    end
    
    def ==(o)
      eql?(o)
    end
    
    def hash
      internal_node.hashCode
    end
    
    #
    # Returns a hash of all properties {key => value, ...}
    #
    def properties
      ret = {}
      iter = @internal_node.getPropertyKeys.iterator
      while (iter.hasNext) do
        key = iter.next
        ret << {key => @internal_node.getProperty(key)}
      end
      ret
    end

    
    # INHERIT_OR_INCLUDE_PROC is proc that contains code that 
    # is used both in the inherited and the included methods.
    # TODO must be a nicer way of doing this ?
    INHERIT_OR_INCLUDE_PROC = proc do |c|
      c.extend(ClassMethods)
      c.properties :classname      
      
      # This method adds a MetaNode for each class that inherits from the Node
      # must avoid endless recursion 
      return if c == Neo::BaseNode or c == Neo::MetaNode or c == Neo::MetaNodes 
      
      # create a new @meta_node since it does not exist
      # the @meta node represents this class (holds the references to instance of it etc)
      meta_node = Neo::MetaNode.new do |n|
        n.meta_classname = c.to_s
        Neo::neo_service.meta_nodes.nodes << n
      end      
      c.instance_eval {
        @meta_node = meta_node 
      }
    end
    
    
    #
    # Implements the inherited hook that will be called when someone
    # inherits from this class.
    # 
    # This method does:
    # * Creates a MetaNode and adds a relationship from the Neo::neo_service.meta_nodes.nodes
    # * Creates a class method 'meta_node' that will return this meta node
    #
    def self.included(c)
      Neo::Node::INHERIT_OR_INCLUDE_PROC.call c

      $neo_logger.info{"included: created MetaNode for '#{c.to_s}'"}
    end

    # --------------------------------------------------------------------------
    # Node class methods
    #
    module ClassMethods


      #
      #  Returns all the instance of this class
      #   
      def all
        @meta_node.instances.to_a
      end
      
      
      #
      # Returns a meta node corresponding to this class.
      # This meta_node is an class instance variable (and not a class variable)
      #
      def meta_node
        @meta_node
      end
    
      def inherited(c)
        Neo::Node::INHERIT_OR_INCLUDE_PROC.call c
        $neo_logger.info{"inherited: created MetaNode for '#{c.to_s}'"}
      end
    
      #
      # Allows to declare Neo properties.
      # Notice that you do not need to declare any properties in order to 
      # set and get a neo property.
      # An undeclared setter/getter will be handled in the method_missing method instead.
      #
      def properties(*props)
        props.each do |prop|
          define_method(prop) do 
            @internal_node.get_property(prop.to_s)
          end

          name = (prop.to_s() +"=")
          define_method(name) do |value|
            @internal_node.set_property(prop.to_s, value)
          end
        end
      end
    
    
      #
      # Allows to declare Neo relationsships.
      # The speficied name will be used as the type of the neo relationship.
      #
      def add_relation_type(type)
        define_method(type) do 
          Relations.new(self,type.to_s)
        end
      end
    
    
      def relations(*relations)
        relations.each {|type| add_relation_type(type)}
      end
    end

  end
  
  class BaseNode 
    include Neo::Node
    
    #    def initialize(*args, &block)
    #      # we have to call the init_internal_node
    #      # super does not work when chaining initialize in mixins, see
    #      # http://groups.google.com/group/ruby-talk-google/msg/f38239bcaeb70648
    #      init_internal_node(*args, &block)
    #    end
    
  end
  
  
  #
  # Holds the class name of an Neo node.
  # Used for example to create a Ruby object from a neo node.
  #
  class MetaNode < Neo::BaseNode
    properties :meta_classname # the name of the ruby class it represent
    relations :instances
    
  end

  #
  # A container node for all MetaNode
  #
  class MetaNodes < Neo::BaseNode
    relations :nodes
  end


  
end