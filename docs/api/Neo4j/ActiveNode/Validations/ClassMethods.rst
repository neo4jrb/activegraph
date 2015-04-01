ClassMethods
============




.. toctree::
   :maxdepth: 3
   :titlesonly:


   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/validations.rb:16 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/validations.rb#L16>`_





Methods
-------


.. _ClassMethods_validates_uniqueness_of:

**#validates_uniqueness_of**
  

  .. hidden-code-block:: ruby

     def validates_uniqueness_of(*attr_names)
       validates_with UniquenessValidator, _merge_attributes(attr_names)
     end





