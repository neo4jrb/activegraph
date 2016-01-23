QueryProxyMethodsOfMassUpdating
===============================






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/query/query_proxy_methods_of_mass_updating.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/query/query_proxy_methods_of_mass_updating.rb#L4>`_





Methods
-------



.. _`Neo4j/ActiveNode/Query/QueryProxyMethodsOfMassUpdating#delete`:

**#delete**
  Deletes the relationship between a node and its last link in the QueryProxy chain. Executed in the database, callbacks will not run.

  .. code-block:: ruby

     def delete(node)
       self.match_to(node).query.delete(rel_var).exec
       clear_source_object_cache
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethodsOfMassUpdating#delete_all`:

**#delete_all**
  Deletes a group of nodes and relationships within a QP chain. When identifier is omitted, it will remove the last link in the chain.
  The optional argument must be a node identifier. A relationship identifier will result in a Cypher Error

  .. code-block:: ruby

     def delete_all(identifier = nil)
       query_with_target(identifier) do |target|
         begin
           self.query.with(target).optional_match("(#{target})-[#{target}_rel]-()").delete("#{target}, #{target}_rel").exec
         rescue Neo4j::Session::CypherError
           self.query.delete(target).exec
         end
         clear_source_object_cache
       end
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethodsOfMassUpdating#delete_all_rels`:

**#delete_all_rels**
  Deletes the relationships between all nodes for the last step in the QueryProxy chain.  Executed in the database, callbacks will not be run.

  .. code-block:: ruby

     def delete_all_rels
       return unless start_object && start_object._persisted_obj
       self.query.delete(rel_var).exec
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethodsOfMassUpdating#destroy`:

**#destroy**
  Returns all relationships between a node and its last link in the QueryProxy chain, destroys them in Ruby. Callbacks will be run.

  .. code-block:: ruby

     def destroy(node)
       self.rels_to(node).map!(&:destroy)
       clear_source_object_cache
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethodsOfMassUpdating#replace_with`:

**#replace_with**
  Deletes the relationships between all nodes for the last step in the QueryProxy chain and replaces them with relationships to the given nodes.
  Executed in the database, callbacks will not be run.

  .. code-block:: ruby

     def replace_with(node_or_nodes)
       nodes = Array(node_or_nodes)
     
       self.delete_all_rels
       nodes.each { |node| self << node }
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethodsOfMassUpdating#update_all`:

**#update_all**
  Updates some attributes of a group of nodes within a QP chain.
  The optional argument makes sense only of `updates` is a string.

  .. code-block:: ruby

     def update_all(updates, params = {})
       # Move this to ActiveNode module?
       update_all_with_query(identity, updates, params)
     end



.. _`Neo4j/ActiveNode/Query/QueryProxyMethodsOfMassUpdating#update_all_rels`:

**#update_all_rels**
  Updates some attributes of a group of relationships within a QP chain.
  The optional argument makes sense only of `updates` is a string.

  .. code-block:: ruby

     def update_all_rels(updates, params = {})
       fail 'Cannot update rels without a relationship variable.' unless @rel_var
       update_all_with_query(@rel_var, updates, params)
     end





