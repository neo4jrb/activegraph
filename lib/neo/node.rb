require 'neo/relations'

module Neo

  #
  # Represent a node in the Neo space.
  # 
  # Is a wrapper around a Java neo node
  # 
  #
  class Node
    attr_reader :internal_node 
    
    #
    # Must be run in an transaction unless a block is given 
    # If a block is given a new transaction will be created
    #    
    def initialize(*args)
      if args.length == 1 and args[0].kind_of?(org.neo4j.api.core.Node)
        @internal_node = args[0]
        self.classname = self.class.to_s unless @internal_node.hasProperty("classname")
        $neo_logger.debug {"created '#{self.class.to_s}' using provided java neo node id #{@internal_node.getId()}"}
      elsif block_given? # check if we should run in a transaction
        Neo.transaction { init_internal; yield self }
        $neo_logger.debug {"created '#{self.class.to_s}' with a new transaction"}        
      else
        init_internal
        $neo_logger.debug {"created '#{self.class.to_s}' without a new transaction"}                
      end
    end
    
    def init_internal
      @internal_node = Neo::neo_service.create_node
      self.classname = self.class.to_s
      # TODO set classname node to point to self
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
        err = "method '#{name}' has wrong number of arguments (#{args.size} for #{expected_args})"
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
    
    def to_s
      iter = @internal_node.getPropertyKeys.iterator
      s = self.class.to_s
      if !iter.hasNext 
        s << " no properties"
      else
        s << " Properties: ["
        while (iter.hasNext) do
          p = iter.next
          s << "['#{p}' = '#{@internal_node.getProperty(p)}']"
          s << ', ' if iter.hasNext
        end
        s << "]"
      end
      s
    end
    
    # --------------------------------------------------------------------------
    # Node class methods
    #
    
    
    def self.inherited(c)
      # This method adds a MetaNode for each class that inherits from the Node
      # must avoid endless recursion 
      if c == MetaNode or c == MetaNodes
        return
      end
      
      # create a meta node representing the new class
      # TODO check: should only be created once  ?      
      metanode = MetaNode.new do |n|
        n.meta_classname = c.to_s
        Neo::neo_service.meta_nodes.nodes << n
      end
      
      # define the 'meta_node' method in the new class
      classname = class << c;  self;  end
      classname.send :define_method, :meta_node do
        metanode
      end      

      $neo_logger.debug{"created MetaNode for '#{c.to_s}'"}
    end

    
    #
    # Allows to declare Neo properties.
    # Notice that you do not need to declare any properties in order to 
    # set and get a neo property.
    # An undeclared setter/getter will handled in the method_missing method instead.
    #
    def self.properties(*props)
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
    def self.add_relation_type(type)
      define_method(type) do 
        Relations.new(self,type.to_s)
      end
    end
    
    
    def self.relations(*relations)
      relations.each {|type| add_relation_type(type)}
    end

    properties :classname
  end
  
  
  #
  # Holds the class name of an Neo node.
  # Used for example to create a Ruby object from a neo node.
  #
  class MetaNode < Node
    properties :meta_classname # the name of the ruby class it represent
    relations :instances
  end

  #
  # A container node for all MetaNode
  #
  class MetaNodes < Node
    relations :nodes
  end
  
end