require 'neo4j/relations'
require 'neo4j/lucene_query'


module Neo4j

  #
  # Represent a node in the Neo4j space.
  # 
  # Is a wrapper around a Java neo node
  # 
  #
  module Node
    attr_reader :internal_node 
    
    #
    # Must be run in a transaction unless a block is given 
    # If a block is given a new transaction will be created
    # 
    # Does
    # * sets the neo property 'classname' to self.class.to_s
    # * creates a neo node java object (in @internal_node)
    # * creates a relationship in the metanode instance to this instance
    #    
    def initialize(*args)
      $NEO_LOGGER.debug("Initialize #{self}")
      # was a neo java node provided ?
      if args.length == 1 and args[0].kind_of?(org.neo4j.api.core.Node)
        Transaction.run {init_with_node(args[0])} unless Transaction.running?
        init_with_node(args[0])                   if Transaction.running?
      elsif block_given? 
        Transaction.run {init_without_node; yield self} unless Transaction.running?        
        begin init_without_node; yield self end         if Transaction.running?                
      else 
        Transaction.run {init_without_node} unless Transaction.running?        
        init_without_node                   if Transaction.running?                
      end
      
      # must call super with no arguments so that chaining of initialize method will work
      super() 
    end
    
    #
    # Inits this node with the specified java neo node
    #
    def init_with_node(node)
      @internal_node = node
      self.classname = self.class.to_s unless @internal_node.hasProperty("classname")
      $NEO_LOGGER.debug {"loading node '#{self.class.to_s}' node id #{@internal_node.getId()}"}
    end
    
    
    #
    # Inits when no neo java node exists. Must create a new neo java node first.
    #
    def init_without_node
      @internal_node = Neo4j::Neo.instance.create_node
      self.classname = self.class.to_s
      update_meta_node_instances self.class
      $NEO_LOGGER.debug {"created new node '#{self.class.to_s}' node id: #{@internal_node.getId()}"}        
    end
    
    def update_meta_node_instances(clazz)
      meta_node = clazz.meta_node
      # $NEO_LOGGER.warn("No meta_node for #{self} type #{self.class.to_s}") if meta_node.nil?
      return if meta_node.nil?
      
      # add the instance to the list of instances in the meta node      
      # self.class.meta_node.nil might be nil since it could be a MetaNode
      meta_node.instances << self
      
      clazz.ancestors.each do |a|
        next if a == clazz 
        next unless a.respond_to?(:meta_node)
        update_meta_node_instances a
      end
    end

    
    #
    # A hook used to set and get undeclared properties
    #
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
          $NEO_LOGGER.warn("Missing property '#{name}' for class '#{self.class.to_s}' id :#{neo_node_id}")
          return nil # TODO hmm, should we allow this. Maybe only declared props should do this
          # super.method_missing(methodname, *args)
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
    def props
      ret = {}
      iter = @internal_node.getPropertyKeys.iterator
      while (iter.hasNext) do
        key = iter.next
        ret[key] = @internal_node.getProperty(key)
      end
      ret
    end



    #
    #  Index all declared properties
    #
    def index
      clazz = self.class
      id    = neo_node_id.to_s

      fields = {}
      clazz.decl_props.each do |k|
        key = k.to_s
        fields[key] = props[key]
      end
      
      #      Neo4j::Neo.instance.lucene.index(id, fields)
      
      Neo.instance.index_node(self)
    end

    
   
    # INHERIT_OR_INCLUDE_PROC is proc that contains code that 
    # is used both in the inherited and the included methods.
    # TODO must be a nicer way of doing this ?
    INHERIT_OR_INCLUDE_PROC = proc do |c|
      c.extend(ClassMethods)
      c.properties :classname      
      
      # This method adds a MetaNode for each class that inherits from the Node
      # must avoid endless recursion 
      return if c == Neo4j::BaseNode or c == Neo4j::MetaNode or c == Neo4j::MetaNodes 
      
      # create a new @meta_node since it does not exist
      # the @meta node represents this class (holds the references to instance of it etc)
      meta_node = Neo4j::MetaNode.new do |n|
        n.ref_classname = c.to_s
        Neo4j::Neo.instance.meta_nodes.nodes << n
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
    # * Creates a MetaNode and adds a relationship from the Neo4j::neo_service.meta_nodes.nodes
    # * Creates a class method 'meta_node' that will return this meta node
    #
    def self.included(c)
      Neo4j::Node::INHERIT_OR_INCLUDE_PROC.call c
    end

    # --------------------------------------------------------------------------
    # Node class methods
    #
    module ClassMethods
      attr_reader :decl_props

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
        Neo4j::Node::INHERIT_OR_INCLUDE_PROC.call c
      end
    
      #
      # Allows to declare Neo4j properties.
      # Notice that you do not need to declare any properties in order to 
      # set and get a neo property.
      # An undeclared setter/getter will be handled in the method_missing method instead.
      #
      def properties(*props)
        @decl_props ||= []        
        props.each do |prop|
          @decl_props << prop
          define_method(prop) do 
            @internal_node.get_property(prop.to_s)
          end

          name = (prop.to_s() +"=")
          define_method(name) do |value|
            @internal_node.set_property(prop.to_s, value)
            # TODO: performance , we here reindex everytime a property changes ...
            index
          end
        end
      end
    
    
      #
      # Allows to declare Neo4j relationsships.
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
      
      #
      # Finds all nodes of this type (and ancestors of this type) having
      # the specified property values.
      # 
      # == Example
      #   MyNode.find(:name => 'foo', :company => 'bar')
      #
      def find(query)
        #        q = query.dup
        #        q['classname'] = self.to_s
        ids = LuceneQuery.find(index_storage_path, query)
#        ids = Neo4j::Neo.instance.lucene.find(q)
        
        # TODO performance, we load all the found entries. Maybe better using Enumeration
        # and load it when needed
        ids.collect {|id| Neo4j::Neo.instance.find_node(id)}
      end      

      #
      # The location of the lucene index for this node.
      #
      def index_storage_path
        Neo4j::Neo.instance.index_storage + "/" + self.to_s.gsub('::', '/')
      end
      
    end

  end
  
  class BaseNode 
    include Neo4j::Node
  end
  
  
  #
  # Holds the class name of an Neo4j node.
  # Used for example to create a Ruby object from a neo node.
  #
  class MetaNode < Neo4j::BaseNode
    properties :ref_classname # the name of the ruby class it represent
    relations :instances
    
    def index
      # overriding super index since we do not want to index these nodes
    end
  end

  #
  # A container node for all MetaNode
  #
  class MetaNodes < Neo4j::BaseNode
    relations :nodes
    
    def index
      # overriding super index since we do not want to index these nodes
    end
    
  end


  
end