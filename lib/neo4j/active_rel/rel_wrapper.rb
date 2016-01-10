require 'neo4j/core/relationship'

wrapping_proc = Proc.new do |relationship|
  Neo4j::NodeWrapping.wrapper(relationship)
end
Neo4j::Core::Relationship.wrapper_callback(wrapping_proc)

module Neo4j
  module NodeWrapping
    class << self
      def wrapper(rel)
        rel.props.symbolize_keys!
        begin
          most_concrete_class = class_from_type(rel.rel_type)
          most_concrete_class.constantize.new
        rescue NameError => e
          raise e unless e.message.match(/uninitialized constant/)

          return rel
        end.tap do |wrapped_rel|
          wrapped_rel.init_on_load(rel, rel.start_node_id, rel.end_node_id, rel.type)
        end
      end

      def class_from_type(rel_type)
        Neo4j::ActiveRel::Types::WRAPPED_CLASSES[rel_type] || Neo4j::ActiveRel::Types::WRAPPED_CLASSES[rel_type] = rel_type.to_s.camelize
      end
    end
  end
end
