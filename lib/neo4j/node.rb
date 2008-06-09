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
      $NEO_LOGGER.debug {"created new node '#{self.class.to_s}' node id: #{@internal_node.getId()}"}        
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
        set_property(name, args[0])
      else
        get_property(name)
      end
    end
    
    
    #
    # Set a neo property on this node.
    # You should not use this method, instead set property like you do in Ruby:
    # 
    #   n = Node.new
    #   n.foo = 'hej'
    # 
    # Runs in a new transaction if there is not one already running,
    # otherwise it will run in the existing transaction.
    #
    def set_property(name, value)
      $NEO_LOGGER.debug{"set property '#{name}'='#{value}'"}      
      Transaction.run {
        @internal_node.set_property(name, value)
      }
    end
 
    # 
    # Returns the value of the given neo property.
    # You should not use this method, instead use get properties like you do in Ruby:
    # 
    #   n = Node.new
    #   n.foo = 'hej'
    #   puts n.foo
    # 
    # The n.foo call will intern use this method.
    # If the property does not exist it will return nil.
    # Runs in a new transaction if there is not one already running,
    # otherwise it will run in the existing transaction.
    #    
    def get_property(name)
      $NEO_LOGGER.debug{"get property '#{name}'"}        
      
      Transaction.run {
        return nil if ! has_property(name)
        @internal_node.get_property(name)
      }
    end
    
    #
    # Checks if the given neo property exists.
    # Runs in a new transaction if there is not one already running,
    # otherwise it will run in the existing transaction.
    #
    def has_property(name)
      Transaction.run {
        @internal_node.has_property(name)
      }
    end
    
    # 
    # Returns a unique id
    # Calls getId on the neo node java object
    #
    def neo_node_id
      @internal_node.getId()
    end

    def eql?(o)    
      o.kind_of?(Node) && o.internal_node == internal_node
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
      fields = {}
      self.class.decl_props.each do |k|
        key = k.to_s
        fields[key] = props[key]
      end
      
      Neo.instance.index_node(self)
    end

    
    #
    # Deletes this node.
    # Invoking any methods on this node after delete() has returned is invalid and may lead to unspecified behavior.
    # Runs in a new transaction if one is not already running.
    #
    def delete
      Transaction.run {  @internal_node.delete }
    end
    
    
    #
    # Returns an array of nodes that has a relation from this
    #
    def relations
      Relations.new(@internal_node)
    end
   
    #
    # Adds classmethods in the ClassMethods module
    #
    def self.included(c)
      c.extend ClassMethods
    end

    # --------------------------------------------------------------------------
    # Node class methods
    #
    module ClassMethods
      attr_reader :decl_props

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
            get_property(prop.to_s)
            #            @internal_node.get_property(prop.to_s)
          end

          name = (prop.to_s() +"=")
          define_method(name) do |value|
            Transaction.run do
              set_property(prop.to_s, value)
              #@internal_node.set_property(prop.to_s, value)
              index
            end
          end
        end
      end
    
    
      #
      # Allows to declare Neo4j relationsships.
      # The speficied name will be used as the type of the neo relationship.
      #
      def add_relation_type(type)
        define_method(type) do 
          NodesWithRelationType.new(self,type.to_s)
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
        ids = LuceneQuery.find(index_storage_path, query)
        
        # TODO performance, we load all the found entries. Maybe better using Enumeration
        # and load it when needed
        Transaction.run do
          ids.collect {|id| Neo4j::Neo.instance.find_node(id)}
        end
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
  
end