module Neo4j
  module Rails
    class RecordNotFoundError < StandardError
    end

    module Finders
      extend ActiveSupport::Concern

      included do
        rule(:_all, :functions => Neo4j::Rule::Functions::Count.new)
      end

      module ClassMethods
        # overwrite the index method to add find_by_xxx class methods
        def index(*args)
          field = args.first

          if self._decl_props[field.to_sym] && self._decl_props[field.to_sym][:type] == Fixnum
            module_eval <<-RUBY, __FILE__, __LINE__
              def self.all_by_#{field}(value)
                find_with_indexer(:#{field} => value)
              end
  	  		  def self.find_by_#{field}(value)
	  	        all_by_#{field}(value).first
		  	  end
            RUBY
          else
            module_eval <<-RUBY, __FILE__, __LINE__
              def self.all_by_#{field}(value)
                find_with_indexer("#{field}: \\"\#{value}\\"")
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
          result = ids.map { |id| entity_load(id) }
          if ids.length == 1
            result.first
          else
            result
          end
        end

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
        def find(*args)
          case args.first
            when :all, :first
              kind = args.shift
              send(kind, *args)
            when "0", 0, nil
              nil
            else
              if convertable_to_id?(args.first)
                find_with_ids(*args)
              else
                first(*args)
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

        def all(*args)
          if !conditions_in?(*args)
            # use the _all rule to recover all the stored instances of this node
            _all
          else
            # handle the special case of a search by id
            ids = ids_in(args.first)
            if ids
              [find_with_ids(ids)].flatten
            else
              find_with_indexer(*args)
            end
          end
        end

        def first(*args)
          all(*args).first
        end

        def last(*args)
          a = all(*args)
          a.empty? ? nil : a[a.size - 1]
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
          entity.is_a? self
        end

        def find_with_indexer(*args)
          hits                                     = _indexer.find(*args)
          # We need to save this so that the Rack Neo4j::Rails:LuceneConnection::Closer can close it
          Thread.current[:neo4j_lucene_connection] ||= []
          Thread.current[:neo4j_lucene_connection] << hits
          hits
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
          first(:conditions => attrs) || send(method, attrs, &block)
        end
      end
    end
  end
end

