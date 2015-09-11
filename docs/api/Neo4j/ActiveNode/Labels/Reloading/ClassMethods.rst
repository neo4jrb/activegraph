ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   




Constants
---------





Files
-----



  * `lib/neo4j/active_node/labels/reloading.rb:12 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/labels/reloading.rb#L12>`_





Methods
-------



.. _`Neo4j/ActiveNode/Labels/Reloading/ClassMethods#before_remove_const`:

**#before_remove_const**
  

  .. code-block:: ruby

     def before_remove_const
       associations.each_value(&:queue_model_refresh!)
       MODELS_FOR_LABELS_CACHE.clear
       WRAPPED_CLASSES.each { |c| MODELS_TO_RELOAD << c.name }
       WRAPPED_CLASSES.clear
     end





