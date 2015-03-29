ClassMethods
============




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * lib/neo4j/active_node/scope.rb:7





Methods
-------


**#_call_scope_context**
  

  .. hidden-code-block:: ruby

     def _call_scope_context(eval_context, query_params, proc)
       if proc.arity == 1
         eval_context.instance_exec(query_params, &proc)
       else
         eval_context.instance_exec(&proc)
       end
     end


**#_scope**
  

  .. hidden-code-block:: ruby

     def _scope
       @_scope ||= {}
     end


**#all**
  

  .. hidden-code-block:: ruby

     def all
       if current_scope
         current_scope.clone
       else
         self.as(:n)
       end
     end


**#current_scope**
  :nodoc:

  .. hidden-code-block:: ruby

     def current_scope #:nodoc:
       ScopeRegistry.value_for(:current_scope, base_class.to_s)
     end


**#current_scope=**
  :nodoc:

  .. hidden-code-block:: ruby

     def current_scope=(scope) #:nodoc:
       ScopeRegistry.set_value_for(:current_scope, base_class.to_s, scope)
     end


**#has_scope?**
  rubocop:disable Style/PredicateName

  .. hidden-code-block:: ruby

     def has_scope?(name)
       ActiveSupport::Deprecation.warn 'has_scope? is deprecated and may be removed from future releases, use scope? instead.', caller
     
       scope?(name)
     end


**#scope**
  Similar to ActiveRecord scope

  .. hidden-code-block:: ruby

     def scope(name, proc)
       _scope[name.to_sym] = proc
     
       define_method(name) do |query_params = nil, some_var = nil, query_proxy = nil|
         self.class.send(name, query_params, some_var, query_proxy)
       end
     
       klass = class << self; self; end
       klass.instance_eval do
         define_method(name) do |query_params = nil, _ = nil, query_proxy = nil|
           eval_context = ScopeEvalContext.new(self, query_proxy || self.query_proxy)
           proc = _scope[name.to_sym]
           _call_scope_context(eval_context, query_params, proc)
         end
       end
     end


**#scope?**
  rubocop:enable Style/PredicateName

  .. hidden-code-block:: ruby

     def scope?(name)
       _scope.key?(name.to_sym)
     end





