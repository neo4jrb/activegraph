Config
======




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------



  * DEFAULT_FILE



Files
-----



  * lib/neo4j/config.rb:6





Methods
-------


**#[]**
  

  .. hidden-code-block:: ruby

     def [](key)
       configuration[key.to_s]
     end


**#[]=**
  Sets the value of a config entry.

  .. hidden-code-block:: ruby

     def []=(key, val)
       configuration[key.to_s] = val
     end


**#class_name_property**
  

  .. hidden-code-block:: ruby

     def class_name_property
       Neo4j::Config[:class_name_property] || :_classname
     end


**#configuration**
  Reads from the default_file if configuration is not set already

  .. hidden-code-block:: ruby

     def configuration
       return @configuration if @configuration
     
       @configuration = ActiveSupport::HashWithIndifferentAccess.new
       @configuration.merge!(defaults)
       @configuration
     end


**#default_file**
  

  .. hidden-code-block:: ruby

     def default_file
       @default_file ||= DEFAULT_FILE
     end


**#default_file=**
  Sets the location of the configuration YAML file and old deletes configurations.

  .. hidden-code-block:: ruby

     def default_file=(file_path)
       delete_all
       @defaults = nil
       @default_file = File.expand_path(file_path)
     end


**#defaults**
  

  .. hidden-code-block:: ruby

     def defaults
       require 'yaml'
       @defaults ||= ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file(default_file))
     end


**#delete**
  Remove the value of a config entry.

  .. hidden-code-block:: ruby

     def delete(key)
       configuration.delete(key)
     end


**#delete_all**
  Remove all configuration. This can be useful for testing purpose.

  .. hidden-code-block:: ruby

     def delete_all
       @configuration = nil
     end


**#include_root_in_json**
  

  .. hidden-code-block:: ruby

     def include_root_in_json
       # we use ternary because a simple || will always evaluate true
       Neo4j::Config[:include_root_in_json].nil? ? true : Neo4j::Config[:include_root_in_json]
     end


**#to_hash**
  

  .. hidden-code-block:: ruby

     def to_hash
       configuration.to_hash
     end


**#to_yaml**
  

  .. hidden-code-block:: ruby

     def to_yaml
       configuration.to_yaml
     end


**#use**
  Yields the configuration

  .. hidden-code-block:: ruby

     def use
       @configuration ||= ActiveSupport::HashWithIndifferentAccess.new
       yield @configuration
       nil
     end





