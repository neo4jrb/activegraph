module Neo4j
  module Rails
    class RecordNotFoundError < StandardError
    end

    # Defines {ClassMethods}
    module Finders
      extend ActiveSupport::Concern


      # @private
      def reachable_from_ref_node?
        # All relationships are reachable
        respond_to?(:_java_rel) || Neo4j::Algo.all_path(self.class.ref_node_for_class, self).outgoing(self.class).outgoing(:_all).first != nil
      end

      included do
        rule(:_all, :functions => Neo4j::Wrapper::Rule::Functions::Size.new) if respond_to?(:rule)
      end

      # Defines the #{#find} method. When declaring properties with index a number of finder methods will be generated,
      # similar to active record, example +find_by_<property_name>+, +find_or_create_by_<property_name>. +all_by_<property_name>+
      #
      # @example find_or_create_by
      #   class Person < Neo4j::Rails::Model
      #     property :age, :type => Fixnum
      #   end
      #
      #   Person.find_by_age(42)
      #   Person.find_or_create_by
      #   Person.find_or_create_by!(:age => 'bla')
      #
      # @example find all
      #   Person.all_by_age
      #   Person.all(:name => 'bla')
      #   Person.all('name: "bla"')  # lucene query syntax
      #
      # @see Neo4j::Rails::Attributes::ClassMethods#property
      # @see #find
      #
      module ClassMethods

        # @private
        def index_prefix
          return "" unless Neo4j.running?
          return "" unless respond_to?(:ref_node_for_class)
          ref_node = ref_node_for_class.wrapper
          prefix = ref_node.respond_to?(:index_prefix) ? ref_node.send(:index_prefix) : ref_node[:name]
          prefix ? prefix + "_" : ""
        end

        # @private
        # overwrite the index method to add find_by_xxx class methods
        def index(*args)
          field = args.first

          if self._decl_props[field.to_sym] && self._decl_props[field.to_sym][:type] == Fixnum
            module_eval <<-RUBY, __FILE__, __LINE__
              def self.all_by_#{field}(value)
                find_with_indexer_or_traversal(:#{field} => value)
              end
  	  		  def self.find_by_#{field}(value)
	  	        all_by_#{field}(value).first
		  	  end
            RUBY
          else
            module_eval <<-RUBY, __FILE__, __LINE__
              def self.all_by_#{field}(value)
                find_with_indexer_or_traversal("#{field}: \\"\#{value}\\"")
              end

              def self.find_by_#{field}(value)
                all_by_#{field}(value).first
              end
            RUBY
          end
          super
        end

        # load an id or array of ids from the database
        def load(*ids)
          result = ids.map { |id| load_entity(id) }
          if ids.length == 1
            result.first
          else
            result
          end
        end

        Neo4j::Wrapper::Find.send(:alias_method, :_wrapper_find, :find)

        # Behave like the ActiveRecord query interface
        #
        # === Example
        #
        #   Handle Model.find(params[:id])
        #   Model.find
        #   Model.find(:first)
        #   Model.find("1")
        #   Model.find(1)
        #   Model.find("name: test")
        #   Model.find(:name => "test")
        #   Model.find(:first, "name: test")
        #   Model.find(:first, { :name => "test" })
        #   Model.find(:first, :conditions => "name: test")
        #   Model.find(:first, :conditions => { :name => "test" })
        #   Model.find(:all, "name: test")
        #   Model.find(:all, { :name => "test" })
        #   Model.find(:all, :conditions => "name: test")
        #   Model.find(:all, :conditions => { :name => "test" })
        #
        def find(*args, &block)
          case args.first
            when :all, :first
              kind = args.shift
              send(kind, *args, &block)
            when "0", 0, nil
              nil
            else
              if convertable_to_id?(args.first)
                find_with_ids(*args)
              else
                first(*args, &block)
              end
          end
        end

        # Finds a model by given id or matching given criteria.
        # When node not found, raises RecordNotFoundError
        def find!(*args)
          self.find(*args).tap do |result|
            raise Neo4j::Rails::RecordNotFoundError if result.nil?
          end
        end

        # Find the first Node given the conditions, or creates a new node
        # with the conditions that were supplied.
        #
        # @example Find or create the node.
        #   Person.find_or_create_by(:name => "test")
        #
        # @param [ Hash ] attrs The attributes to check.
        #
        # @return [ Node ] A matching or newly created node.
        def find_or_create_by(attrs = {}, &block)
          find_or(:create, attrs, &block)
        end

        # Similar to find_or_create_by,calls create! instead of create
        # Raises RecordInvalidError if model is invalid.
        def find_or_create_by!(attrs = {}, &block)
          find_or(:create!, attrs, &block)
        end

        # Find the first Node given the conditions, or initializes a new node
        # with the conditions that were supplied.
        #
        # @example Find or initialize the node.
        #   Person.find_or_initialize_by(:name => "test")
        #
        # @param [ Hash ] attrs The attributes to check.
        #
        # @return [ Node ] A matching or newly initialized node.
        def find_or_initialize_by(attrs = {}, &block)
          find_or(:new, attrs, &block)
        end

        def all(*args, &block)
          if !conditions_in?(*args)
            # use the _all rule to recover all the stored instances of this node
            _all
          else
            # handle the special case of a search by id
            ids = ids_in(args.first)
            if ids
              [find_with_ids(ids)].flatten
            else
              find_with_indexer_or_traversal(*args, &block)
            end
          end
        end

        def first(*args, &block)
          found = all(*args, &block).first
          if found && args.first.is_a?(Hash) && args.first.include?(:id)
            # if search for an id then all the other properties must match
            args.first.find{|k,v| k != :id && found.send(k) != v} ? nil : found
          else
            found
          end
        end

        def last(*args)
          a = all(*args)
          a.empty? ? nil : a[all.size - 1]
        end

        def count
          all.size
        end

        # Call this method if you are using Neo4j::Rails::Model outside rails
        # This method is automatically called by rails to close all lucene connections.
        def close_lucene_connections
          Thread.current[:neo4j_lucene_connection].each {|hits| hits.close} if Thread.current[:neo4j_lucene_connection]
          Thread.current[:neo4j_lucene_connection] = nil
        end

        protected

        def ids_in(arg)
          return nil unless arg.is_a?(Hash)
          condition = arg[:conditions].present? ? arg[:conditions] : arg
          condition.is_a?(Hash) && condition[:id]
        end

        def convertable_to_id?(value)
          return false unless value
          value.is_a?(Integer) || (value.is_a?(String) && value =~ /^[+-]?\d+$/)
        end

        def conditions_in?(*args)
          return false if args.empty?

          # does it contain an string, which will be treated like a condition ?
          return true if args.find { |a| a.is_a?(String) }

          # does it contain an empty conditions param ?
          hash = args.find { |a| a.is_a?(Hash) }
          if hash
            return false if hash.include?(:conditions) && hash[:conditions].empty?

            # does it contain only paging or sorting params ?
            !hash.except(:sort, :page, :per_page).empty?
          else
            return false
          end
        end

        def find_with_ids(*args)
          result = load(*args.map { |p| p.to_i })
          if result.is_a?(Array)
            result = result.select { |r| findable?(r)}
          else
            result = nil unless findable?(result)
          end
          result
        end

        def findable?(entity)
          entity.is_a?(self) and entity.reachable_from_ref_node?
        end

        
        def use_traversal_finder?(*args)
          # Conditions for using a traversal:
          # 1. the first argument is a hash
          return false unless args.first.is_a?(Hash)
          
          # 2. no support for :condition hash
          return false if args.first.include?(:conditions)
          
          # 3. there is at least one property which does not have a lucene index
          args.first.keys.find{|k| !index?(k)}
        end


        def find_with_indexer_or_traversal(*args, &block)
          if use_traversal_finder?(*args)
            find_with_traversal(args.first)
          else
            find_with_indexer(*args, &block)
          end
        end

        def find_with_indexer(*args, &block)
          hits = if args.first.is_a?(Hash) && args.first.include?(:conditions)
                   params = args.first.clone
                   params.delete(:conditions)
                   raise "ARGS #{args.inspect}" if args.size > 1
                   _wrapper_find(args.first[:conditions], params, &block)
                 else
                   _wrapper_find(*args, &block)
                 end


          # We need to save this so that the Rack Neo4j::Rails:LuceneConnection::Closer can close it
          Thread.current[:neo4j_lucene_connection] ||= []
          Thread.current[:neo4j_lucene_connection] << hits if hits.respond_to?(:close)
          hits
        end

        def find_with_traversal(conditions)
          this = self
          all.query do |cypher|
            conditions.each_pair do |k,v|
              if this._decl_rels.keys.include?(k)
                n = node(v.id)
                rel_name = rel(this._decl_rels[k].rel_type)
                this._decl_rels[k].dir == :outgoing ? cypher > rel_name > n : cypher < rel_name < n
              else
                cypher[k] == v
              end
            end
          end
        end

        # Find the first object or create/initialize it.
        #
        # @example Find or perform an action.
        #   Person.find_or(:create, :name => "Dev")
        #
        # @param [ Symbol ] method The method to invoke.
        # @param [ Hash ] attrs The attributes to query or set.
        #
        # @return [ Node ] The first or new node.
        def find_or(method, attrs = {}, &block)
          first(attrs) || send(method, attrs, &block)
        end
      end
    end
  end
end

