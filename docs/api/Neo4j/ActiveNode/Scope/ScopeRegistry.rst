ScopeRegistry
=============



Stolen from ActiveRecord
https://github.com/rails/rails/blob/08754f12e65a9ec79633a605e986d0f1ffa4b251/activerecord/lib/active_record/scoping.rb#L57


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   




Constants
---------



  * VALID_SCOPE_TYPES



Files
-----



  * `lib/neo4j/active_node/scope.rb:112 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/scope.rb#L112>`_





Methods
-------



.. _`Neo4j/ActiveNode/Scope/ScopeRegistry#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize
       @registry = Hash.new { |hash, key| hash[key] = {} }
     end



.. _`Neo4j/ActiveNode/Scope/ScopeRegistry#set_value_for`:

**#set_value_for**
  Sets the +value+ for a given +scope_type+ and +variable_name+.

  .. code-block:: ruby

     def set_value_for(scope_type, variable_name, value)
       raise_invalid_scope_type!(scope_type)
       @registry[scope_type][variable_name] = value
     end



.. _`Neo4j/ActiveNode/Scope/ScopeRegistry#value_for`:

**#value_for**
  Obtains the value for a given +scope_name+ and +variable_name+.

  .. code-block:: ruby

     def value_for(scope_type, variable_name)
       raise_invalid_scope_type!(scope_type)
       @registry[scope_type][variable_name]
     end





