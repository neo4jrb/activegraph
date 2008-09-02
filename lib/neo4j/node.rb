require 'neo4j/relations'
require 'neo4j/events'
require 'lucene'

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
    # Will create a new transaction if one is not already running.
    # If a block is given a new transaction will be created.
    # 
    # Does
    # * sets the neo property 'classname' to self.class.to_s
    # * creates a neo node java object (in @internal_node)
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
      self.class.fire_event NodeCreatedEvent.new(self)
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
        old_value = get_property(name)
        @internal_node.set_property(name, value)
        if (name != 'classname')  # do not want events on internal properties
          event = PropertyChangedEvent.new(self, name.to_sym, old_value, value)
          self.class.fire_event(event)
        end
        
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
        @internal_node.get_property(name.to_s)
      }
    end
    
    #
    # Checks if the given neo property exists.
    # Runs in a new transaction if there is not one already running,
    # otherwise it will run in the existing transaction.
    #
    def has_property(name)
      Transaction.run {
        @internal_node.has_property(name.to_s)
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
    def update_index
      $NEO_LOGGER.debug("Index #{neo_node_id}")
      doc = {:id => neo_node_id}
      
      $NEO_LOGGER.debug("FIELDS to index #{self.class.decl_props.inspect}")
      self.class.decl_props.each do |k|
        key = k.to_s
        value = get_property(k)
        next if value.nil? # or value.empty?
        $NEO_LOGGER.debug("Add field '#{key}' = '#{value}'")
        doc.merge!({key => value})
      end

      lucene_index << doc
    end

    def lucene_index
      self.class.lucene_index
    end
    
    #
    # Deletes this node.
    # Invoking any methods on this node after delete() has returned is invalid and may lead to unspecified behavior.
    # Runs in a new transaction if one is not already running.
    #
    def delete
      Transaction.run { |t|
        relations.each {|r| r.delete}
        @internal_node.delete 
        lucene_index.delete(neo_node_id)
      }
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
      # all subclasses share the same index, declared properties and listeners
      c.instance_eval do
        const_set(:LUCENE_INDEX_PATH, Neo4j::LUCENE_INDEX_STORAGE + "/" + self.to_s.gsub('::', '/'))
        const_set(:DECL_PROPS, [])
        const_set(:LISTENERS, [])
      end unless c.const_defined?(:LUCENE_INDEX_PATH)
      
      c.extend ClassMethods
    end

    # --------------------------------------------------------------------------
    # Node class methods
    #
    module ClassMethods

      #
      # Access to class constants.
      # These properties are shared by the class and its siblings.
      # For example that means that we can specify properties for a parent
      # class and the child classes will 'inherit' those properties.
      # 
      
      
      def lucene_index
        Lucene::Index.new(self::LUCENE_INDEX_PATH)      
      end
        
      def listeners
        self::LISTENERS
      end
      
      def decl_props
        self::DECL_PROPS
      end
      
      
      # ------------------------------------------------------------------------
      # Event listener
      
      def add_listener(&block)
        listeners << block
        block
      end
      
      def remove_listener(listener)
        listeners.delete(listener)
      end
      
      def fire_event(event)
        listeners.each {|p| p.call event}
      end
      
      
      #
      # Index a relationship
      # Register an event listener on the rel_clazz that will keep
      # the lucene index synchronized.
      #
      def index(rel_clazz, lucene_rel_name, &block)
        rel_clazz.add_listener do |event|
          rel_name = default_name_for_relationship(self.to_s)
#          puts "Relation #{event} clazz #{event.node.to_s} #{rel_name} empty: #{event.node.relations.outgoing(rel_name.to_sym).empty?.to_s}"
          if (!event.node.relations.outgoing(rel_name.to_sym).empty?)
            value = event.node.instance_eval(&block)
            update_relation_index(event.node, lucene_rel_name, value)     
          end
        end
      end
      
     
      def update_relation_index(other_node, key, value)
        # generate a unique id
        id = "#{other_node.neo_node_id}.#{key}"
        $NEO_LOGGER.debug("update_relation_index #{id} key: '#{key}', value: '#{value}'")

        # need to index both the class and node id of the other node since it might be deleted
        doc = {:id => id, key => value, :_neo_rel_class => other_node.class.to_s, :_neo_rel_id => other_node.neo_node_id}
        lucene_index << doc
      end
    
      
      # ------------------------------------------------------------------------

      #
      # Allows to declare Neo4j properties.
      # Notice that you do not need to declare any properties in order to 
      # set and get a neo property.
      # An undeclared setter/getter will be handled in the method_missing method instead.
      #
      def properties(*props)
        props.each do |prop|
          decl_props << prop
          define_method(prop) do 
            get_property(prop.to_s)
          end

          name = (prop.to_s() +"=")
          define_method(name) do |value|
            Transaction.run do
              set_property(prop.to_s, value)
              update_index
            end
          end
        end
      end
    
    
      #
      # Allows to declare Neo4j relationsships.
      # The speficied name will be used as the type of the neo relationship.
      #
      def add_relation_type(rel_name)
        # This code will be nicer in Ruby 1.9, can't use define_method
        module_eval(%Q{def #{rel_name}(&block)
                        NodesWithRelationType.new(self,'#{rel_name.to_s}', &block)
                    end},  __FILE__, __LINE__)
      end
    
    
      def relations(*relations)
        relations.each {|type| add_relation_type(type)}
      end
      
      
      # Specifies a relationship between two node classes.
      # Expects type of relation and class. Example:
      #       
      #   class Order
      #      # default last parameter will be :order_lines
      #      contains :one_or_more, OrderLine 
      #      is_contained_in :one_and_only_one, Customer
      #   end
      #      
      def contains(multiplicity, clazz, name=default_name_for_relationship(clazz))
        add_relation_type(name)
      end
      
      #
      # Returns the default name of relationship to a other node class.
      #
      def default_name_for_relationship(clazz)
        # TODO remove namespace :: 
        name = Inflector.pluralize(clazz.to_s)
        Inflector.underscore(name)
      end      
      
      #
      # Finds all nodes of this type (and ancestors of this type) having
      # the specified property values.
      # 
      # == Example
      #   MyNode.find(:name => 'foo', :company => 'bar')
      #   
      # Or using a DSL query
      #   MyNode.find{(name == 'foo') & (company == 'bar')}
      #   
      # See the lucene module for more information how to do a query.
      #
      def find(query=nil, &block)
        hits = lucene_index.find(query, &block)
        #ids = LuceneQuery.find(index_storage_path, query)
        
        # TODO performance, we load all the found entries. Maybe better using Enumeration
        # and load it when needed. Wrap it in a SearchResult
        Transaction.run do
          hits.collect do |doc| 
            id = doc[:id]
            node = Neo4j::Neo.instance.find_node(id.to_i)
            raise LuceneIndexOutOfSyncException.new("lucene found node #{id} but it does not exist in neo") if node.nil?
            node
          end
        end
      end      
    end

  end
  
  class BaseNode 
    include Neo4j::Node
  end
  
end