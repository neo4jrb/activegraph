require 'neo4j/traversal/filter_predicate'
require 'neo4j/traversal/prune_evaluator'
require 'neo4j/traversal/rel_expander'
require 'neo4j/traversal/traverser'

module Neo4j
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
    #   me.outgoing(:friends).each {|friend| puts friend[:name]}
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
    # Of course all the methods <tt>outgoing</tt>, <tt>incoming</tt>, <tt>both</tt>, <tt>depth</tt>, <tt>include_start_node</tt>, <tt>filter</tt>, and <tt>prune</tt> can be combined.
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
    # See #outgoing
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
    # See #outgoing
    #
    def both(type=nil)
      if type
        Traverser.new(self).both(type)
      else
        Traverser.new(self) # default is both
      end
    end

  end
end