module Neo4j
  # A script for renaming relationship
  # In Neo4j.rb version 2.0.0 the relationship declared with has_n(something).to(otherclass)
  # has changed. In order to change the relationship of an already existing database you can run this script.
  # Uses the @NEO4J_CLASSES@ and @NEO4J_MULTI_TENANCY_CLASSES@ environment variables.
  # Usage see the github wiki pages upgrade
  module UpgradeV2

    class << self

      # The domain classes declared as global ref_nodes
      def default_domains_nodes
        domain_nodes = [Neo4j.default_ref_node]
        multi_tenancy_classes.each{|clazz| domain_nodes += clazz._all.to_a}
        domain_nodes
      end

      def neo4j_classes
        abort("Please set the environment variable 'NEO4J_CLASSES' or ruby constant ($NEO4J_CLASSES) before running this task") unless ENV['NEO4J_CLASSES']
        ENV['NEO4J_CLASSES'].split(',').map(&:strip).map{|c| Neo4j::Wrapper.to_class(c)}
      end

      def multi_tenancy_classes
        (ENV['NEO4J_MULTI_TENANCY_CLASSES'] && ENV['NEO4J_MULTI_TENANCY_CLASSES'].split(',').map(&:strip).map{|c| Neo4j::Wrapper.to_class(c)}) || []
      end

      def migrate_all!(domains = default_domains_nodes)
        $NEO4J_CLASSES ||= neo4j_classes

        puts "Upgrading #{$NEO4J_CLASSES.join(', ')}"
        puts "Number of domains (multitenancy)  #{domains.size}"

        domains.each do |domain|
          puts "domain #{domain.props.inspect} (multitenancy) "  if domain != Neo4j.default_ref_node
          ::Neo4j.threadlocal_ref_node = domain
          $NEO4J_CLASSES.each { |clazz| migrate(clazz) }
        end
      end

      def migrate(clazz, nodes = clazz._all)
        puts "migrate 2.0 #{clazz} ..."
        source_class = clazz

        rule_node =  Neo4j::Wrapper::Rule::Rule.rule_node_for(clazz).rule_node

        if rule_node.property?(:_count__all__classname)
          puts "Rename size property on #{clazz}, #{rule_node[:_count__all__classname]}"
          Neo4j::Transaction.run do
            rule_node[:_size__all__classname] = rule_node[:_count__all__classname]
            rule_node[:_count__all__classname] = nil
          end
        end

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

