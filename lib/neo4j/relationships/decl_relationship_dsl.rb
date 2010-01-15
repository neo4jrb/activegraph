module Neo4j

  module Relationships

    # A DSL for declared relationships like has_n.
    #
    # :api: private
    class DeclRelationshipDsl #:nodoc:

      attr_reader :type, :cascade_delete_prop_name, :counter, :rel_id
      CASCADE_DELETE_PROP_NAMES = { :outgoing => :_cascade_delete_outgoing, :incoming => :_cascade_delete_incoming}

      def initialize(rel_id, params)
        @outgoing = true
        @rel_id = rel_id
        @type = rel_id
        @namespace_type = rel_id
        @cascade_delete_prop_name = CASCADE_DELETE_PROP_NAMES[params[:cascade_delete]]
        @counter = params[:counter] == true
      end

      def counter?
        @counter
      end

      def clazz
        @class
      end

      def cascade_delete?
        !@cascade_delete_prop_name.nil?
      end

      def class_and_type_from_args(args)
        if (args.size > 1)
          return args[0], args[1]
        else
          return args[0], @rel_id
        end
      end

      def namespace_type
        @class.nil? ? @type.to_s : "#{@class.to_s}##{@type.to_s}"
      end


      def outgoing?
        @outgoing
      end


      def to(*args)
        @outgoing = true
        @class, @type = class_and_type_from_args(args)
        self
      end

      def from(*args) #(clazz, type)
        @outgoing = false
        @class, @type = class_and_type_from_args(args)
        self
      end

      def relationship(rel_class)
        @relationship = rel_class
        self
      end

      def relationship_class
        @relationship
      end
    end
  end
end
