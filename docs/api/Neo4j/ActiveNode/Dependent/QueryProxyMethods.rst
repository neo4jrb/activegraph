QueryProxyMethods
=================




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/dependent/query_proxy_methods.rb:5 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/dependent/query_proxy_methods.rb#L5>`_





Methods
-------


.. _QueryProxyMethods_each_for_destruction:

**#each_for_destruction**
  Used as part of `dependent: :destroy` and may not have any utility otherwise.
  It keeps track of the node responsible for a cascading `destroy` process.
  but this is not always available, so we require it explicitly.

  .. hidden-code-block:: ruby

     def each_for_destruction(owning_node)
       target = owning_node.called_by || owning_node
       objects = enumerable_query(identity).compact.reject do |obj|
         target.dependent_children.include?(obj)
       end
     
       objects.each do |obj|
         obj.called_by = target
         target.dependent_children << obj
         yield obj
       end
     end


.. _QueryProxyMethods_unique_nodes:

**#unique_nodes**
  This will match nodes who only have a single relationship of a given type.
  It's used  by `dependent: :delete_orphans` and `dependent: :destroy_orphans` and may not have much utility otherwise.

  .. hidden-code-block:: ruby

     def unique_nodes(association, self_identifer, other_node, other_rel)
       fail 'Only supported by in QueryProxy chains started by an instance' unless caller
     
       unique_nodes_query(association, self_identifer, other_node, other_rel)
         .proxy_as(association.target_class, other_node)
     end





