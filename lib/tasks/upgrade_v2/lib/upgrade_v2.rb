# A script for renaming relationship
# In Ne4j.rb version 2.0.0 the relationship declared with has_n(something).to(otherclass)
# has changed. In order to change the relationship of an already existing database you can run this script.
# Use the migrate_all! to automatically update all Neo4j::Rails::Model classes
# For Neo4j::NodeMixin nodes you need to migrate each node using the migrate method (since there are no automatic way of finding all instances of an Neo4j::NodeMixin)

$NEO4J_CLASSES = []
$DOMAIN_CLASSES = []

module Neo4j
  module Rails
    class Model
      class << self
        alias_method :_old_inherited, :inherited

        def inherited(c)
          _old_inherited(c)
          unless c == Neo4j::Rails::Model
            $NEO4J_CLASSES << c
            $DOMAIN_CLASSES << c if c.respond_to?(:ref_node_for_class)
          end
        end
      end
    end
  end
end

module Neo4j
  module UpgradeV2 #:nodoc:

    class << self

      # The domain classes declared as global ref_nodes
      def default_domains_nodes
        domain_nodes = [Neo4j.default_ref_node]
        $DOMAIN_CLASSES.each{|clazz| domain_nodes += clazz._all.to_a}
        domain_nodes
      end

      def migrate_all!(domains = default_domains_nodes)
        domains.each do |domain|
          puts "domain #{domain.props.inspect} (multitenancy) "  if domain != Neo4j.default_ref_node
          ::Neo4j.threadlocal_ref_node = domain
          $NEO4J_CLASSES.each { |clazz| migrate(clazz) }
        end
      end

      def migrate(clazz, nodes = clazz._all)
        puts "migrate #{clazz} ..."
        source_class = clazz

        clazz._decl_rels.keys.each do |rel_accessor|
          target_class = clazz._decl_rels[rel_accessor].target_class
          next unless target_class

          old_rel = "#{target_class}##{rel_accessor}"
          new_rel = "#{source_class}##{rel_accessor}"

          TransactionalExec.new(100) do |node|
            node._java_node._rels(:outgoing, old_rel).each do |rel|
              start_node = rel._start_node
              end_node = rel._end_node
              props = rel.props
              rel.del
              Neo4j::Relationship.new(new_rel, start_node, end_node, props)
            end
          end.execute(nodes)
        end
      end

    end

    class TransactionalExec
      attr_accessor :commit_every, :block

      def initialize(commit_every, &block)
        @commit_every = commit_every
        @block = block
      end

      def execute(enumerable)
        time_of_all = Time.now
        tx = Neo4j::Transaction.new
        time_in_ruby = Time.now
        index = 0
        enumerable.each do |item|

          @block.call(item)
          index += 1
          if (index % @commit_every == 0)
            time_spent_in_ruby_code = Time.now - time_in_ruby
            time_spent_in_write_to_file = Time.now
            tx.success
            tx.finish
            tx = Neo4j::Transaction.new
            puts "  Written #{index} items. time_spend_in_ruby_code: #{time_spent_in_ruby_code}, time_spent_in_write_to_file #{Time.now - time_spent_in_write_to_file}"
            time_in_ruby = Time.now
          end
        end

        tx.success
        tx.finish
        puts "Total, written #{index} items in #{Time.now - time_of_all} sec." if index != 0
      end
    end

  end

end

