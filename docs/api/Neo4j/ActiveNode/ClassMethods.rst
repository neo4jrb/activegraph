ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   




Constants
---------





Files
-----



  * `lib/neo4j/active_node.rb:57 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node.rb#L57>`_

  * `lib/neo4j/active_node/orm_adapter.rb:5 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/orm_adapter.rb#L5>`_





Methods
-------



.. _`Neo4j/ActiveNode/ClassMethods#nodeify`:

**#nodeify**
  

  .. code-block:: ruby

     def nodeify(object)
       if object.is_a?(::Neo4j::ActiveNode) || object.nil?
         object
       else
         self.find(object)
       end
     end





