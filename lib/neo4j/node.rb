module Neo4j

  
  class LuceneIndexOutOfSyncException < StandardError
    
  end
  #
  # Represent a node in the Neo4j space.
  # 
  # Is a wrapper around a Java neo node
  # 
  #
  module Node
    attr_reader :internal_node 

    extend Transactional
    
    #
    # Will create a new transaction if one is not already running.
    # If a block is given a new transaction will be created.
    # 
    # Does
    # * sets the neo property 'classname' to self.class.to_s
    # * creates a neo node java object (in @internal_node)
    #    
    def initialize(*args)
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
      self.class.fire_event NodeCreatedEvent.new(self)      
      $NEO_LOGGER.debug {"created new node '#{self.class.to_s}' node id: #{@internal_node.getId()}"}        
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
      old_value = get_property(name)
      @internal_node.set_property(name, value)
      if (name != 'classname')  # do not want events on internal properties
        event = PropertyChangedEvent.new(self, name.to_sym, old_value, value)
        self.class.fire_event(event)
      end
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
      
      return nil if ! has_property(name)
      @internal_node.get_property(name.to_s)
    end
    
    #
    # Checks if the given neo property exists.
    # Runs in a new transaction if there is not one already running,
    # otherwise it will run in the existing transaction.
    #
    def has_property(name)
      @internal_node.has_property(name.to_s) unless @internal_node.nil?
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


    def lucene_index
      self.class.lucene_index
    end
    
    #
    # Deletes this node.
    # Invoking any methods on this node after delete() has returned is invalid and may lead to unspecified behavior.
    # Runs in a new transaction if one is not already running.
    #
    def delete
      relations.each {|r| r.delete}
      @internal_node.delete 
      lucene_index.delete(neo_node_id)
      self.class.fire_event(NodeDeletedEvent.new(self))        
    end
    

    def classname
      get_property('classname')
    end
    
    def classname=(value)
      set_property('classname', value)
    end
    
    #
    # Returns an array of nodes that has a relation from this
    #
    def relations
      Relations.new(@internal_node)
    end


    def reindex
      doc = {:id => neo_node_id }
      self.class.index_updaters.each do |updater|
        updater.call(self, doc)
      end
      lucene_index << doc
    end

    
    transactional :has_property, :set_property, :get_property, :delete


    
    #
    # Adds classmethods in the ClassMethods module
    #
    def self.included(c)
      # all subclasses share the same index, declared properties and index_updaters
      c.instance_eval do
        const_set(:LUCENE_INDEX_PATH, Neo4j::LUCENE_INDEX_STORAGE + "/" + self.to_s.gsub('::', '/'))
        const_set(:INDEX_UPDATERS, [])
        const_set(:INDEX_TRIGGERS, [])
        const_set(:RELATIONS_INFO, {})
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
        
      def index_updaters
        self::INDEX_UPDATERS
      end

      def index_triggers
        self::INDEX_TRIGGERS
      end

      
      #
      # Contains information of all relationships, name, type, and multiplicity
      # 
      def relations_info
        self::RELATIONS_INFO
      end
      
      
      # ------------------------------------------------------------------------
      # Event index_updater
      
      def fire_event(event)
        index_triggers.each {|trigger| trigger.call(event.node, event)}
        #Neo4j::Transaction.current.reindex(event.node) # ??? TODO reindex after a transaction finish
      end
      
      
      # ------------------------------------------------------------------------

      #
      # Declares Neo4j node properties.
      # You need to declare properties in order to set them unless you include the Neo4j::DynamicAccessor mixin.
      #
      def properties(*props)
        props.each do |prop|
          define_method(prop) do 
            get_property(prop.to_s)
          end

          name = (prop.to_s() +"=")
          define_method(name) do |value|
            set_property(prop.to_s, value)
          end
        end
      end
    
      
      
      # when Order with a relationship to Customer
      # For each customer in an order update total_cost
      # index "orders.total_cost"
      def index(rel_prop)
        rel, prop = rel_prop.to_s.split('.')
        index_property(rel) if prop.nil?
        index_relation(rel_prop, rel,prop) unless prop.nil?
      end

      def index_property(prop)
        updater = lambda do |node, doc| 
          doc[prop] = node.send(prop)
        end
        index_updaters << updater
        
        trigger = lambda do |node, event|
          node.reindex if event.match?(Neo4j::PropertyChangedEvent, :property, prop)
        end
        index_triggers << trigger
      end
      
      
      def index_relation(index_key, rel, prop)
        rel_type = relations_info[rel.to_sym][:rel_type]
        
        # updater
        updater = lambda do |customer, doc| 
          values = []
          relations = customer.relations.both(rel_type.to_sym).nodes 
          relations.each {|order| values << order.send(prop)}
          doc[index_key] = values
        end
        index_updaters << updater
      
        # trigger
        trigger = lambda do |order, event|
          if event.match?(Neo4j::PropertyChangedEvent, :property, prop)
            relations = order.relations.both(rel_type.to_sym).nodes
            relations.each {|r| r.send(:reindex)} 
          end
        end
        clazz = relations_info[rel.to_sym][:class]
        clazz.index_triggers << trigger
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

      def add_single_relation_type(rel_name)
        # This code will be nicer in Ruby 1.9, can't use define_method
        # TODO refactoring ! error handling etc ..
        module_eval(%Q{def #{rel_name}=(value)
                        r = NodesWithRelationType.new(self,'#{rel_name.to_s}')
                        r << value
                    end},  __FILE__, __LINE__)
        
        module_eval(%Q{def #{rel_name}
                        r = NodesWithRelationType.new(self,'#{rel_name.to_s}')
                        r.to_a[0]
                    end},  __FILE__, __LINE__)
      end
      

      #      
      # Specifies a relationship between two node classes.
      # Expects type of relation and class. Example:
      #       
      #   class Order
      #      # default last parameter will be :order_lines
      #      has :one_or_more, OrderLine 
      #      has :one_and_only_one, Customer
      #   end
      #      
      def has(multiplicity, rel_name, clazz, rel_type = rel_name)
        add_relation_type(rel_type) unless singular?(multiplicity)
        add_single_relation_type(rel_type) if singular?(multiplicity)
        relations_info[rel_name] = {:multiplicity => multiplicity, :class => clazz, :rel_type => rel_type, :outgoing => true, :relation => Neo4j::DynamicRelation}
      end

      

      #
      # Defines a method for navigation to incoming relationships
      # Example 
      # class Customer
      #   belongs :zero_or_more, :orders, Order, :customer
      # end
      # 
      # The third parameter is by default plural of the second parameter if multiplicity does
      # not end with _or_more
      # 
      def belongs_to(multiplicity, rel_name, clazz, rel_type)
        relations_info[rel_name] = {:multiplicity => multiplicity, :rel_type => rel_type, :class => clazz, :outgoing => false}        
      end
      
      #
      # Creates a new relation. The relation must be outgoing.
      # 
      def new_relation(rel_name, internal_relation)
        relations_info[rel_name.to_sym][:relation].new(internal_relation) # internal_relation is a java neo object
      end
      
      def singular?(name)
        name.to_s =~ /one$/
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
end