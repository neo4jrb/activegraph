Config
======



== Keeps configuration for neo4j

== Configurations keys


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------



  * DEFAULT_FILE

  * CLASS_NAME_PROPERTY_KEY



Files
-----



  * `lib/neo4j/config.rb:5 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/config.rb#L5>`_





Methods
-------



.. _`Neo4j/Config.[]`:

**.[]**
  

  .. code-block:: ruby

     def [](key)
       configuration[key.to_s]
     end



.. _`Neo4j/Config.[]=`:

**.[]=**
  Sets the value of a config entry.

  .. code-block:: ruby

     def []=(key, val)
       configuration[key.to_s] = val
     end



.. _`Neo4j/Config.association_model_namespace`:

**.association_model_namespace**
  

  .. code-block:: ruby

     def association_model_namespace
       Neo4j::Config[:association_model_namespace] || nil
     end



.. _`Neo4j/Config.association_model_namespace_string`:

**.association_model_namespace_string**
  

  .. code-block:: ruby

     def association_model_namespace_string
       namespace = Neo4j::Config[:association_model_namespace]
       return nil if namespace.nil?
       "::#{namespace}"
     end



.. _`Neo4j/Config.configuration`:

**.configuration**
  Reads from the default_file if configuration is not set already

  .. code-block:: ruby

     def configuration
       return @configuration if @configuration
     
       @configuration = ActiveSupport::HashWithIndifferentAccess.new
       @configuration.merge!(defaults)
       @configuration
     end



.. _`Neo4j/Config.default_file`:

**.default_file**
  

  .. code-block:: ruby

     def default_file
       @default_file ||= DEFAULT_FILE
     end



.. _`Neo4j/Config.default_file=`:

**.default_file=**
  Sets the location of the configuration YAML file and old deletes configurations.

  .. code-block:: ruby

     def default_file=(file_path)
       delete_all
       @defaults = nil
       @default_file = File.expand_path(file_path)
     end



.. _`Neo4j/Config.defaults`:

**.defaults**
  

  .. code-block:: ruby

     def defaults
       require 'yaml'
       @defaults ||= ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file(default_file))
     end



.. _`Neo4j/Config.delete`:

**.delete**
  Remove the value of a config entry.

  .. code-block:: ruby

     def delete(key)
       configuration.delete(key)
     end



.. _`Neo4j/Config.delete_all`:

**.delete_all**
  Remove all configuration. This can be useful for testing purpose.

  .. code-block:: ruby

     def delete_all
       @configuration = nil
     end



.. _`Neo4j/Config.include_root_in_json`:

**.include_root_in_json**
  

  .. code-block:: ruby

     def include_root_in_json
       # we use ternary because a simple || will always evaluate true
       Neo4j::Config[:include_root_in_json].nil? ? true : Neo4j::Config[:include_root_in_json]
     end



.. _`Neo4j/Config.module_handling`:

**.module_handling**
  

  .. code-block:: ruby

     def module_handling
       Neo4j::Config[:module_handling] || :none
     end



.. _`Neo4j/Config.timestamp_type`:

**.timestamp_type**
  

  .. code-block:: ruby

     def timestamp_type
       Neo4j::Config[:timestamp_type] || DateTime
     end



.. _`Neo4j/Config.to_hash`:

**.to_hash**
  

  .. code-block:: ruby

     def to_hash
       configuration.to_hash
     end



.. _`Neo4j/Config.to_yaml`:

**.to_yaml**
  

  .. code-block:: ruby

     def to_yaml
       configuration.to_yaml
     end



.. _`Neo4j/Config.use`:

**.use**
  Yields the configuration

  .. code-block:: ruby

     def use
       @configuration ||= ActiveSupport::HashWithIndifferentAccess.new
       yield @configuration
       nil
     end





