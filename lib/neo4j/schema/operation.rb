module Neo4j
  module Schema
    class Operation
      attr_reader :label_name, :property, :options

      def initialize(label_name, property, options = default_options)
        @label_name = label_name.to_sym
        @property = property.to_sym
        @options = options
      end

      def self.incompatible_operation_classes
        []
      end

      def create!
        drop_incompatible!
        return if exist?
        schema_query(:"create_#{type}")
      end

      def label_object
        @label_object ||= Neo4j::Label.create(label_name)
      end

      def incompatible_operation_classes
        self.class.incompatible_operation_classes
      end

      def drop!
        schema_query(:"drop_#{type}")
      end

      def drop_incompatible!
        incompatible_operation_classes.each do |clazz|
          operation = clazz.new(label_name, property)
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
        # If there is a transaction going on, this could block
        # So we run in a thread and it will go through at the next opportunity
        Thread.new do
          label_object.send(method, property, options, Neo4j::ActiveBase.schema_session)
        end
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
        label_object.indexes[:property_keys].include?([property])
      end
    end

    class UniqueConstraintOperation < Neo4j::Schema::Operation
      def self.incompatible_operation_classes
        [ExactIndexOperation]
      end

      def type
        'constraint'
      end

      def create!
        return if exist?
        super
      end

      def exist?
        Neo4j::Label.constraint?(label_name, property)
      end

      def default_options
        {type: :unique}
      end
    end
  end
end
