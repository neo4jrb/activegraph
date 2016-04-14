ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   

   

   

   

   

   

   

   




Constants
---------



  * VALID_OPTIONS_FOR_ENUMS

  * DEFAULT_OPTIONS_FOR_ENUMS



Files
-----



  * `lib/neo4j/shared/enum.rb:7 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/enum.rb#L7>`_





Methods
-------



.. _`Neo4j/Shared/Enum/ClassMethods#enum`:

**#enum**
  Similar to ActiveRecord enum, maps an integer value on the database to
  a set of enum keys.

  .. code-block:: ruby

     def enum(parameters = {})
       options, parameters = *split_options_and_parameters(parameters)
       parameters.each do |property_name, enum_keys|
         enum_keys = normalize_key_list enum_keys
         @neo4j_enum_data ||= {}
         @neo4j_enum_data[property_name] = enum_keys
         define_property(property_name, enum_keys, options)
         define_enum_methods(property_name, enum_keys, options)
       end
     end



.. _`Neo4j/Shared/Enum/ClassMethods#neo4j_enum_data`:

**#neo4j_enum_data**
  Returns the value of attribute neo4j_enum_data

  .. code-block:: ruby

     def neo4j_enum_data
       @neo4j_enum_data
     end





