Wrapper
=======



The wrapping process is what transforms a raw CypherNode or EmbeddedNode from Neo4j::Core into a healthy ActiveNode (or ActiveRel) object.


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   




Constants
---------



  * CONSTANTS_FOR_LABELS_CACHE



Files
-----



  * `lib/neo4j/active_node/node_wrapper.rb:5 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/node_wrapper.rb#L5>`_





Methods
-------



.. _`Neo4j/Node/Wrapper#class_to_wrap`:

**#class_to_wrap**
  

  .. code-block:: ruby

     def class_to_wrap
       load_classes_from_labels
       Neo4j::ActiveNode::Labels.model_for_labels(labels).tap do |model_class|
         Neo4j::Node::Wrapper.populate_constants_for_labels_cache(model_class, labels)
       end
     end



.. _`Neo4j/Node/Wrapper#wrapper`:

**#wrapper**
  this is a plugin in the neo4j-core so that the Ruby wrapper will be wrapped around the Neo4j::Node objects

  .. code-block:: ruby

     def wrapper
       found_class = class_to_wrap
       return self if not found_class
     
       found_class.new.tap do |wrapped_node|
         wrapped_node.init_on_load(self, self.props)
       end
     end





