module Neo4j
  module ActiveRel
    # Provides a mapping between neo4j rel types and Ruby classes
    module RelType
      extend ActiveSupport::Concern

      WRAPPED_CLASSES = []

      # @return the rel type
      # @see Neo4j-core
      def rel_type
        @_persisted_rel ? @_persisted_rel.rel_type.to_sym : self.class.to_s.underscore.to_sym
      end

      def self.included(klass)
        add_wrapped_class(klass)
      end

      def self.add_wrapped_class(klass)
        _wrapped_classes << klass
        @_wrapped_rel_types = nil
      end

      def self._wrapped_classes
        Neo4j::ActiveRel::RelType::WRAPPED_CLASSES
      end

      protected

      # Only for testing purpose
      # @private
      def self._wrapped_rel_types=(wrt)
        @_wrapped_rel_types=(wrt)
      end

      def self._wrapped_rel_types
        @_wrapped_rel_types ||=  _wrapped_classes.inject({}) do |ack, clazz|
          ack.tap do |a|
            a[clazz.mapped_rel_type.to_sym] = clazz if clazz.respond_to?(:mapped_rel_type)
          end
        end
      end

      module ClassMethods
        # Find all nodes/objects of this class, with given search criteria
        # @param [Hash, nil] args the search critera or nil if finding all
        # @param [Neo4j::Session] session defaults to the model's session
        def all(args = nil, session = self.neo4j_session)
          if (args)
            find_by_hash(args, session)
          else
            Neo4j::Relationship.find_all_rels(mapped_rel_type, session)
          end
        end

        # @return [Fixnum] number of nodes of this class
        def count(session = self.neo4j_session)
          q = session.query("MATCH (a)-[r:`#{mapped_rel_type}`]->(b) RETURN count(r) AS count")
          q.to_a[0][:count]
        end

        # Same as #all but return only one object
        # If given a String or Fixnum it will return the object with that neo4j id.
        # @param [Hash,String,Fixnum] args search criteria
        def find(args, session = self.neo4j_session)
          case args
            when Hash
              find_by_hash(args, session).first
            when String, Fixnum
              Neo4j::Relationship.load(args, mapped_rel_type)
            else
              raise "Unknown argument #{args.class} in find method"
          end
        end

        def first
          all.first
        end

        # separated from protected find_by_hash due to optional session
        def where(args={})
          session = args.delete(:session) ||
                    args.delete('session') ||
                    self.neo4j_session
          find_by_hash(args, session)
        end

        # @return [Symbol] the rel_type that this class has which corresponds to a Ruby class
        def mapped_rel_type
          @_rel_type || self.to_s.underscore.to_sym
        end

        protected

        def find_by_hash(hash, session)
          Neo4j::Relationship.query(mapped_rel_type, {conditions: hash}, session)
        end

        def set_mapped_rel_type(name)
          @_rel_type = name.to_sym
        end
      end
    end
  end
end


