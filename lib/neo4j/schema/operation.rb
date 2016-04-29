module Neo4j
  module Schema
    class Operation
      attr_reader :label, :property, :options

      def initialize(label, property, options = default_options)
        @label = if label.is_a?(Neo4j::Core::Label)
                   label
                 else
                   Neo4j::Core::Label.new(label, ActiveBase.current_session)
                 end

        @property = property.to_sym
        @options = options
      end

      def self.incompatible_operation_classes
        []
      end

      def label_object
        label
      end

      def create!
        drop_incompatible!
        return if exist?
        schema_query(:"create_#{type}")
      end

      def incompatible_operation_classes
        self.class.incompatible_operation_classes
      end

      def drop!
        schema_query(:"drop_#{type}")
      end

      def drop_incompatible!
        incompatible_operation_classes.each do |clazz|
          operation = clazz.new(@label, property)
          operation.drop! if operation.exist?
        end
      end

      def exist?
        fail 'Abstract class, not implemented'
      end

      def default_options
        {}
      end

      def type
        fail 'Abstract class, not implemented'
      end

      private

      def schema_query(method)
        label.send(method, property, options)
      end
    end

    class ExactIndexOperation < Neo4j::Schema::Operation
      def self.incompatible_operation_classes
        [UniqueConstraintOperation]
      end

      def type
        'index'
      end

      def exist?
        label.index?(property)
      end
    end

    class UniqueConstraintOperation < Neo4j::Schema::Operation
      def self.incompatible_operation_classes
        [ExactIndexOperation]
      end

      def type
        'uniqueness_constraint'
      end

      def create!
        return if exist?
        super
      end

      def exist?
        label.uniqueness_constraint?(property)
      end

      def default_options
        {type: :unique}
      end
    end
  end
end
