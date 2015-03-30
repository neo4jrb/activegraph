Wrapper
=======




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/node_wrapper.rb:5 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/node_wrapper.rb#L5>`_





Methods
-------


**#class_to_wrap**
  

  .. hidden-code-block:: ruby

     def class_to_wrap
       load_classes_from_labels
     
       named_class || ::Neo4j::ActiveNode::Labels.model_for_labels(labels)
     end


**#load_classes_from_labels**
  

  .. hidden-code-block:: ruby

     def load_classes_from_labels
       labels.each { |label| label.to_s.constantize }
     rescue NameError
       nil
     end


**#named_class**
  

  .. hidden-code-block:: ruby

     def named_class
       property = Neo4j::Config.class_name_property
     
       self.props[property].constantize if self.props.is_a?(Hash) && self.props.key?(property)
     end


**#wrapper**
  this is a plugin in the neo4j-core so that the Ruby wrapper will be wrapped around the Neo4j::Node objects

  .. hidden-code-block:: ruby

     def wrapper
       found_class = class_to_wrap
       return self if not found_class
     
       found_class.new.tap do |wrapped_node|
         wrapped_node.init_on_load(self, self.props)
       end
     end





