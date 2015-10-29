Reloading
=========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   Reloading/ClassMethods




Constants
---------



  * MODELS_TO_RELOAD



Files
-----



  * `lib/neo4j/active_node/labels/reloading.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/labels/reloading.rb#L2>`_





Methods
-------



.. _`Neo4j/ActiveNode/Labels/Reloading.reload_models!`:

**.reload_models!**
  

  .. code-block:: ruby

     def self.reload_models!
       MODELS_TO_RELOAD.each(&:constantize)
       MODELS_TO_RELOAD.clear
     end





