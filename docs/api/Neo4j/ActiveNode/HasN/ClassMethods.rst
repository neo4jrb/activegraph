ClassMethods
============




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/has_n.rb:79 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/has_n.rb#L79>`_





Methods
-------


**#association?**
  rubocop:enable Style/PredicateName
  :nocov:

  .. hidden-code-block:: ruby

     def association?(name)
       !!associations[name.to_sym]
     end


**#association_query_proxy**
  

  .. hidden-code-block:: ruby

     def association_query_proxy(name, options = {})
       query_proxy = options[:proxy_obj] || default_association_proxy_obj(name)
     
       Neo4j::ActiveNode::Query::QueryProxy.new(associations[name].target_class_or_nil,
                                                associations[name],
                                                {session: neo4j_session,
                                                 query_proxy: query_proxy,
                                                 context: "#{query_proxy.context || self.name}##{name}",
                                                 optional: query_proxy.optional?,
                                                 caller: query_proxy.caller}.merge(options))
     end


**#associations**
  

  .. hidden-code-block:: ruby

     def associations
       @associations || {}
     end


**#build_association**
  

  .. hidden-code-block:: ruby

     def build_association(macro, direction, name, options)
       Neo4j::ActiveNode::HasN::Association.new(macro, direction, name, options).tap do |association|
         @associations ||= {}
         @associations[name] = association
         create_reflection(macro, name, association, self)
       end
     end


**#default_association_proxy_obj**
  

  .. hidden-code-block:: ruby

     def default_association_proxy_obj(name)
       Neo4j::ActiveNode::Query::QueryProxy.new("::#{self.class.name}".constantize,
                                                nil,
                                                session: neo4j_session,
                                                query_proxy: nil,
                                                context: "#{self.name}##{name}")
     end


**#define_class_method**
  rubocop:enable Style/PredicateName

  .. hidden-code-block:: ruby

     def define_class_method(*args, &block)
       klass = class << self; self; end
       klass.instance_eval do
         define_method(*args, &block)
       end
     end


**#define_has_many_methods**
  

  .. hidden-code-block:: ruby

     def define_has_many_methods(name)
       define_method(name) do |node = nil, rel = nil, options = {}|
         return [].freeze unless self._persisted_obj
     
         association_query_proxy(name, {node: node, rel: rel, caller: self}.merge(options))
       end
     
       define_method("#{name}=") do |other_nodes|
         clear_association_cache
         association_query_proxy(name).replace_with(other_nodes)
       end
     
       define_class_method(name) do |node = nil, rel = nil, proxy_obj = nil, options = {}|
         association_query_proxy(name, {node: node, rel: rel, proxy_obj: proxy_obj}.merge(options))
       end
     end


**#define_has_one_methods**
  

  .. hidden-code-block:: ruby

     def define_has_one_methods(name)
       define_method(name) do |node = nil, rel = nil|
         return nil unless self._persisted_obj
     
         result = association_query_proxy(name, node: node, rel: rel)
         association_instance_fetch(result.to_cypher_with_params,
                                    self.class.reflect_on_association(__method__)) { result.first }
       end
     
       define_method("#{name}=") do |other_node|
         validate_persisted_for_association!
         clear_association_cache
         association_query_proxy(name).replace_with(other_node)
       end
     
       define_class_method(name) do |node = nil, rel = nil, query_proxy = nil, options = {}|
         association_query_proxy(name, {query_proxy: query_proxy, node: node, rel: rel}.merge(options))
       end
     end


**#has_association?**
  :nocov:
  rubocop:disable Style/PredicateName

  .. hidden-code-block:: ruby

     def has_association?(name)
       ActiveSupport::Deprecation.warn 'has_association? is deprecated and may be removed from future releases, use association? instead.', caller
     
       association?(name)
     end


**#has_many**
  rubocop:disable Style/PredicateName

  .. hidden-code-block:: ruby

     def has_many(direction, name, options = {})
       name = name.to_sym
       build_association(:has_many, direction, name, options)
     
       define_has_many_methods(name)
     end


**#has_one**
  

  .. hidden-code-block:: ruby

     def has_one(direction, name, options = {})
       name = name.to_sym
       build_association(:has_one, direction, name, options)
     
       define_has_one_methods(name)
     end


**#inherited**
  make sure the inherited classes inherit the <tt>_decl_rels</tt> hash

  .. hidden-code-block:: ruby

     def inherited(klass)
       klass.instance_variable_set(:@associations, associations.clone)
       super
     end





