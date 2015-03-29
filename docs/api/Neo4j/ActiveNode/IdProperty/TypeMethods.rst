TypeMethods
===========




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   




Constants
---------





Files
-----



  * lib/neo4j/active_node/id_property.rb:27





Methods
-------


**#clear_methods**
  

  .. hidden-code-block:: ruby

     def clear_methods(clazz, name)
       clazz.module_eval(%(undef_method :#{name}), __FILE__, __LINE__) if clazz.method_defined?(name)
       clazz.module_eval(%(undef_property :#{name}), __FILE__, __LINE__) if clazz.attribute_names.include?(name.to_s)
     end


**#clear_methods**
  

  .. hidden-code-block:: ruby

     def clear_methods(clazz, name)
       clazz.module_eval(%(undef_method :#{name}), __FILE__, __LINE__) if clazz.method_defined?(name)
       clazz.module_eval(%(undef_property :#{name}), __FILE__, __LINE__) if clazz.attribute_names.include?(name.to_s)
     end


**#define_custom_method**
  

  .. hidden-code-block:: ruby

     def define_custom_method(clazz, name, on)
       clear_methods(clazz, name)
     
       clazz.module_eval(%{
         default_property :#{name} do |instance|
            raise "Specifying custom id_property #{name} on none existing method #{on}" unless instance.respond_to?(:#{on})
            instance.#{on}
         end
     
         def #{name}
            default_property :#{name}
         end
     
         alias_method :id, :#{name}
       }, __FILE__, __LINE__)
     end


**#define_custom_method**
  

  .. hidden-code-block:: ruby

     def define_custom_method(clazz, name, on)
       clear_methods(clazz, name)
     
       clazz.module_eval(%{
         default_property :#{name} do |instance|
            raise "Specifying custom id_property #{name} on none existing method #{on}" unless instance.respond_to?(:#{on})
            instance.#{on}
         end
     
         def #{name}
            default_property :#{name}
         end
     
         alias_method :id, :#{name}
       }, __FILE__, __LINE__)
     end


**#define_id_methods**
  

  .. hidden-code-block:: ruby

     def define_id_methods(clazz, name, conf)
       validate_conf!(conf)
     
       if conf[:on]
         define_custom_method(clazz, name, conf[:on])
       elsif conf[:auto]
         define_uuid_method(clazz, name)
       elsif conf.empty?
         define_property_method(clazz, name)
       end
     end


**#define_id_methods**
  

  .. hidden-code-block:: ruby

     def define_id_methods(clazz, name, conf)
       validate_conf!(conf)
     
       if conf[:on]
         define_custom_method(clazz, name, conf[:on])
       elsif conf[:auto]
         define_uuid_method(clazz, name)
       elsif conf.empty?
         define_property_method(clazz, name)
       end
     end


**#define_property_method**
  

  .. hidden-code-block:: ruby

     def define_property_method(clazz, name)
       clear_methods(clazz, name)
     
       clazz.module_eval(%(
         def id
           _persisted_obj ? #{name.to_sym == :id ? 'attribute(\'id\')' : name} : nil
         end
     
         validates_uniqueness_of :#{name}
     
         property :#{name}
               ), __FILE__, __LINE__)
     end


**#define_property_method**
  

  .. hidden-code-block:: ruby

     def define_property_method(clazz, name)
       clear_methods(clazz, name)
     
       clazz.module_eval(%(
         def id
           _persisted_obj ? #{name.to_sym == :id ? 'attribute(\'id\')' : name} : nil
         end
     
         validates_uniqueness_of :#{name}
     
         property :#{name}
               ), __FILE__, __LINE__)
     end


**#define_uuid_method**
  

  .. hidden-code-block:: ruby

     def define_uuid_method(clazz, name)
       clear_methods(clazz, name)
     
       clazz.module_eval(%(
         default_property :#{name} do
            ::SecureRandom.uuid
         end
     
         def #{name}
            default_property :#{name}
         end
     
         alias_method :id, :#{name}
               ), __FILE__, __LINE__)
     end


**#define_uuid_method**
  

  .. hidden-code-block:: ruby

     def define_uuid_method(clazz, name)
       clear_methods(clazz, name)
     
       clazz.module_eval(%(
         default_property :#{name} do
            ::SecureRandom.uuid
         end
     
         def #{name}
            default_property :#{name}
         end
     
         alias_method :id, :#{name}
               ), __FILE__, __LINE__)
     end


**#validate_conf!**
  

  .. hidden-code-block:: ruby

     def validate_conf!(conf)
       fail "Expected a Hash, got #{conf.class} (#{conf}) for id_property" if !conf.is_a?(Hash)
     
       return if conf[:on]
     
       if conf[:auto]
         fail "only :uuid auto id_property allowed, got #{conf[:auto]}" if conf[:auto] != :uuid
         return
       end
     
       return if conf.empty?
     
       fail "Illegal value #{conf.inspect} for id_property, expected :on or :auto"
     end


**#validate_conf!**
  

  .. hidden-code-block:: ruby

     def validate_conf!(conf)
       fail "Expected a Hash, got #{conf.class} (#{conf}) for id_property" if !conf.is_a?(Hash)
     
       return if conf[:on]
     
       if conf[:auto]
         fail "only :uuid auto id_property allowed, got #{conf[:auto]}" if conf[:auto] != :uuid
         return
       end
     
       return if conf.empty?
     
       fail "Illegal value #{conf.inspect} for id_property, expected :on or :auto"
     end





