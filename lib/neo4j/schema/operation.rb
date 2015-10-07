module Neo4j
  module Schema
    class Operation
      attr_reader :label_name, :property, :options

      def initialize(label_name, property, options = default_options)
        @label_name = label_name
        @property = property
        @options = options
      end

      def create!
        # require 'pry'; binding.pry
        drop_incompatible!
        return if exist?
        label_object.send(:"create_#{type}", property, options)
      end

      def label_object
        @label_object ||= Neo4j::Label.create(label_name)
      end

      def drop!
        label_object.send(:"drop_#{type}", property, options)
      end

      def drop_incompatible!
        fail 'Abstract class, not implemented'
      end

      def exist?
        fail 'Abstract class, not implemented'
      end

      def default_options
        {}
      end
    end

    class ExactIndexOperation < Neo4j::Schema::Operation
      def type
        'index'
      end

      def drop_incompatible!
        operation = UniqueConstraintOperation.new(label_name, property, type: :unique)
        operation.drop! if operation.exist?
      end

      def exist?
        label_object.indexes[:property_keys].include?([property])
      end
    end

    class UniqueConstraintOperation < Neo4j::Schema::Operation
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

      def drop_incompatible!
        operation = ExactIndexOperation.new(label_name, property)
        operation.drop! if operation.exist?
      end

      def default_options
        {type: :unique}
      end
    end
  end
end
