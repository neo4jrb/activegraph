This is a small prototype for a typical graph use case: A file tree with sharing enabled folders and files.
It even demonstrates that using the neo4j.rb traverser is almost as fast as using the underlying Java Traverser API directly.
By wrapper all Java node objects in Ruby objects gives around 40 % slower performance then the Java Traverser API directly.
This can be avoided by setting the raw parameter to true. The neo4j.rb traversals will then only be are around 20 % slower then the Java Traverser API directly.
It is possible to get even better performance without using the Ruby Enumeration and yield:

Here is the Java version:

  neoNode = node._java_node
  size = 0
  child = org.neo4j.graphdb.DynamicRelationshipType.withName 'child'
  traverser = neoNode.traverse(org.neo4j.graphdb.Traverser::Order::DEPTH_FIRST,
                               org.neo4j.graphdb.StopEvaluator::END_OF_GRAPH,
                               org.neo4j.graphdb.ReturnableEvaluator::ALL, child, org.neo4j.graphdb.Direction::OUTGOING )
  while traverser.hasNext()
    node = traverser.next
    if node.hasProperty('size')
      size += node.getProperty('size')
    end
  end
  size

Here is the Ruby Version (around 20% slower then above)

  folder.outgoing(:child).raw(false).depth(:all).inject(0) {|sum, n| n.hasProperty('size') ? sum + n.getProperty('size') : sum}

Here is a Ruby version without using the Ruby Enumeration API and instead using the underlying Java Neo4j Traverser Iterator object, which is even faster:

  traverser = folder.outgoing(:child).raw(true).depth(:all).iterator
  size = 0
  while traverser.hasNext()
    node = traverser.next
    if node.hasProperty('size')
      size += node.getProperty('size')
    end
  end
  size


INSTALLATION

- install JRuby
gem install neo4j cucumber webrat sinatra
jruby -S cucumber