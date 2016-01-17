ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/scope.rb:7 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/scope.rb#L7>`_





Methods
-------



.. _`Neo4j/ActiveNode/Scope/ClassMethods#_call_scope_context`:

**#_call_scope_context**
  

  .. code-block:: ruby

     def _call_scope_context(eval_context, query_params, proc)
       if proc.arity == 1
         eval_context.instance_exec(query_params, &proc)
       else
         eval_context.instance_exec(&proc)
       end
     end



.. _`Neo4j/ActiveNode/Scope/ClassMethods#_scope`:

**#_scope**
  

  .. code-block:: ruby

     def _scope
       @_scope ||= {}
     end



.. _`Neo4j/ActiveNode/Scope/ClassMethods#all`:

**#all**
  

  .. code-block:: ruby

     def all(new_var = nil)
       var = new_var || (current_scope ? current_scope.node_identity : :n)
       if current_scope
         current_scope.new_link(var)
       else
         self.as(var)
       end
     end



.. _`Neo4j/ActiveNode/Scope/ClassMethods#current_scope`:

**#current_scope**
  :nodoc:

  .. code-block:: ruby

     def current_scope #:nodoc:
       ScopeRegistry.value_for(:current_scope, base_class.to_s)
     end



.. _`Neo4j/ActiveNode/Scope/ClassMethods#current_scope=`:

**#current_scope=**
  :nodoc:

  .. code-block:: ruby

     def current_scope=(scope) #:nodoc:
       ScopeRegistry.set_value_for(:current_scope, base_class.to_s, scope)
     end



.. _`Neo4j/ActiveNode/Scope/ClassMethods#has_scope?`:

**#has_scope?**
  rubocop:disable Style/PredicateName

  .. code-block:: ruby

     def has_scope?(name)
       ActiveSupport::Deprecation.warn 'has_scope? is deprecated and may be removed from future releases, use scope? instead.', caller
     
       scope?(name)
     end



.. _`Neo4j/ActiveNode/Scope/ClassMethods#scope`:

**#scope**
  Similar to ActiveRecord scope

  .. code-block:: ruby

     def scope(name, proc)
       _scope[name.to_sym] = proc
     
       klass = class << self; self; end
       klass.instance_eval do
         define_method(name) do |query_params = nil, _ = nil|
           eval_context = ScopeEvalContext.new(self, current_scope || self.query_proxy)
           proc = _scope[name.to_sym]
           _call_scope_context(eval_context, query_params, proc)
         end
       end
     end



.. _`Neo4j/ActiveNode/Scope/ClassMethods#scope?`:

**#scope?**
  rubocop:enable Style/PredicateName

  .. code-block:: ruby

     def scope?(name)
       _scope.key?(name.to_sym)
     end





