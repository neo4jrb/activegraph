RelTypeConverters
=================



This module controls changes to relationship type based on Neo4j::Config.transform_rel_type.
It's used whenever a rel type is automatically determined based on ActiveRel model name or
association type.


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/rel_type_converters.rb:5 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/rel_type_converters.rb#L5>`_





Methods
-------



.. _`Neo4j/Shared/RelTypeConverters#decorated_rel_type`:

**#decorated_rel_type**
  

  .. code-block:: ruby

     def decorated_rel_type(type)
       @decorated_rel_type ||= Neo4j::Shared::RelTypeConverters.decorated_rel_type(type)
     end



.. _`Neo4j/Shared/RelTypeConverters.decorated_rel_type`:

**.decorated_rel_type**
  

  .. code-block:: ruby

     def decorated_rel_type(type)
       type = type.to_s
       decorated_type =  case rel_transformer
                         when :upcase
                           type.underscore.upcase
                         when :downcase
                           type.underscore.downcase
                         when :legacy
                           "##{type.underscore.downcase}"
                         when :none
                           type
                         else
                           type.underscore.upcase
                         end
       decorated_type.tap { |s| s.gsub!('/', '::') if type.include?('::') }
     end



.. _`Neo4j/Shared/RelTypeConverters.rel_transformer`:

**.rel_transformer**
  Determines how relationship types should look when inferred based on association or ActiveRel model name.
  With the exception of `:none`, all options will call `underscore`, so `ThisClass` becomes `this_class`, with capitalization
  determined by the specific option passed.
  Valid options:
  * :upcase - `:this_class`, `ThisClass`, `thiS_claSs` (if you don't like yourself) becomes `THIS_CLASS`
  * :downcase - same as above, only... downcased.
  * :legacy - downcases and prepends `#`, so ThisClass becomes `#this_class`
  * :none - uses the string version of whatever is passed with no modifications

  .. code-block:: ruby

     def rel_transformer
       @rel_transformer ||= Neo4j::Config[:transform_rel_type].nil? ? :upcase : Neo4j::Config[:transform_rel_type]
     end





