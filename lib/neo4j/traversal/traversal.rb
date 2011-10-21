require 'neo4j/traversal/filter_predicate'
require 'neo4j/traversal/prune_evaluator'
require 'neo4j/traversal/rel_expander'
require 'neo4j/traversal/traverser'

module Neo4j

  # Contains methods that are mixin for Neo4j::Node
  # They all return Neo4j::Traversal::Traverser
  # See the {Neo4j.rb Guide: Traversing Relationships and Nodes}[http://neo4j.rubyforge.org/guides/traverser.html]
  #
  module Traversal
    include ToJava

    # A more powerful alternative of #outgoing, #incoming and #both method.
    # You can use this method for example to only traverse nodes based on properties on the relationships
    #
    # ==== Example
    #
    #   some_node.expand { |n| n._rels.find_all { |r| r[:age] > 5 } }.depth(:all).to_a
    #
    # The above traverse all relationships with a property of age > 5
    #
    # See http://neo4j.rubyforge.org/guides/traverser.html
    #
    def expand(&expander)
      Traverser.new(self).expander(&expander)
    end


    # Returns the outgoing nodes for this node.
    #
    # ==== Returns
    # a Neo4j::NodeTraverser which can be used to further specify which nodes should be included
    # in traversal by using the <tt>depth</tt>, <tt>filter</tt> and <tt>prune</tt> methods.
    #
    # ==== Examples
    #   # Find all my friends (nodes of depth 1 of type <tt>friends</tt>)
    #   me.outgoing(:friends).each {|friend| puts friend.name}
    #
    #   # A possible faster way, avoid loading wrapper Ruby classes, instead use raw java neo4j node objects
    #   me.outgoing(:friends).raw.each {|friend| puts friend[:name]}
    #
    #   # Find all my friends and their friends (nodes of depth 1 of type <tt>friends</tt>)
    #   # me.outgoing(:friends).depth(2).each {|friend| puts friend[:name]}
    #
    #   # Find all my friends and include my self in the result
    #   me.outgoing(:friends).depth(4).include_start_node.each {...}
    #
    #   # Find all my friends friends friends, etc. at any depth
    #   me.outgoing(:friends).depth(:all).each {...}
    #
    #   # Find all my friends friends but do not include my friends (only depth == 2)
    #   me.outgoing(:friends).depth(2).filter{|path| path.length == 2}
    #
    #   # Find all my friends but 'cut off' some parts of the traversal path
    #   me.outgoing(:friends).depth(42).prune(|path| an_expression_using_path_returning_true_false }
    #
    #   # Find all my friends and work colleges
    #   me.outgoing(:friends).outgoing(:work).each {...}
    #
    # Of course all the methods <tt>outgoing</tt>, <tt>incoming</tt>, <tt>both</tt>, <tt>depth</tt>, <tt>include_start_node</tt>, <tt>filter</tt>, and <tt>prune</tt>, <tt>eval_paths</tt>, <tt>unique</tt> can be combined.
    #
    # See the {Neo4j.rb Guides}[http://neo4j.rubyforge.org/guides/traverser.html]
    #
    def outgoing(type)
      if type
        Traverser.new(self).outgoing(type)
      else
        raise "Not implemented getting all types of outgoing relationship. Specify a relationship type"
      end
    end


    # Returns the incoming nodes of given type(s).
    #
    # See #outgoing and http://neo4j.rubyforge.org/guides/traverser.html
    #
    def incoming(type)
      if type
        Traverser.new(self).incoming(type)
      else
        raise "Not implemented getting all types of incoming relationship. Specify a relationship type"
      end
    end

    # Returns both incoming and outgoing nodes of given types(s)
    #
    # If a type is not given then it will return all types of relationships.
    #
    # See #outgoing and http://neo4j.rubyforge.org/guides/traverser.html
    #
    def both(type=nil)
      if type
        Traverser.new(self).both(type)
      else
        Traverser.new(self) # default is both
      end
    end


    # Traverse using a block. The block is expected to return one of the following values:
    # * <tt>:exclude_and_continue</tt>
    # * <tt>:exclude_and_prune</tt>
    # * <tt>:include_and_continue</tt>
    # * <tt>:include_and_prune</tt>
    # This value decides if it should continue to traverse and if it should include the node in the traversal result.
    # The block will receive a path argument.
    #
    # ==== Example
    #
    #   @pet0.eval_paths {|path| path.end_node ==  @principal1 ? :include_and_prune : :exclude_and_continue }.unique(:node_path).depth(:all)
    #
    # ==== See also
    #
    # * How to use - http://neo4j.rubyforge.org/guides/traverser.html
    # * the path parameter - http://api.neo4j.org/1.4/org/neo4j/graphdb/Path.html
    # * the #unique method - if paths should be visit more the once, etc...
    #
    def eval_paths(&eval_block)
      Traverser.new(self).eval_paths(&eval_block)
    end

    # Sets uniqueness of nodes or relationships to visit during a traversals.
    #
    # Allowed values
    # * <tt>:node_global</tt>  A node cannot be traversed more than once (default)
    # * <tt>:node_path</tt>  For each returned node there 's a unique path from the start node to it.
    # * <tt>:node_recent</tt>  This is like :node_global, but only guarantees uniqueness among the most recent visited nodes, with a configurable count.
    # * <tt>:none</tt>  No restriction (the user will have to manage it).
    # * <tt>:rel_global</tt>  A relationship cannot be traversed more than once, whereas nodes can.
    # * <tt>:rel_path</tt> :: No restriction (the user will have to manage it).
    # * <tt>:rel_recent</tt>  Same as for :node_recent, but for relationships.
    #
    # See example in #eval_paths
    # See http://api.neo4j.org/1.4/org/neo4j/kernel/Uniqueness.html and http://neo4j.rubyforge.org/guides/traverser.html
    def unique(u)
      Traverser.new(self).unique(u)
    end
  end
end