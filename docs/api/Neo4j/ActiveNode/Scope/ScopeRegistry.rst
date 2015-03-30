ScopeRegistry
=============




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   




Constants
---------



  * VALID_SCOPE_TYPES



Files
-----



  * `lib/neo4j/active_node/scope.rb:116 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/scope.rb#L116>`_





Methods
-------


**#initialize**
  

  .. hidden-code-block:: ruby

     def initialize
       @registry = Hash.new { |hash, key| hash[key] = {} }
     end


**#raise_invalid_scope_type!**
  

  .. hidden-code-block:: ruby

     def raise_invalid_scope_type!(scope_type)
       return if VALID_SCOPE_TYPES.include?(scope_type)
     
       fail ArgumentError, "Invalid scope type '#{scope_type}' sent to the registry. Scope types must be included in VALID_SCOPE_TYPES"
     end


**#set_value_for**
  Sets the +value+ for a given +scope_type+ and +variable_name+.

  .. hidden-code-block:: ruby

     def set_value_for(scope_type, variable_name, value)
       raise_invalid_scope_type!(scope_type)
       @registry[scope_type][variable_name] = value
     end


**#value_for**
  Obtains the value for a given +scope_name+ and +variable_name+.

  .. hidden-code-block:: ruby

     def value_for(scope_type, variable_name)
       raise_invalid_scope_type!(scope_type)
       @registry[scope_type][variable_name]
     end





