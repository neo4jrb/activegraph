Labels
======



Provides a mapping between neo4j labels and Ruby classes


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   Labels/InvalidQueryError

   Labels/RecordNotFound

   

   

   

   

   

   

   

   

   

   Labels/ClassMethods

   Labels/Reloading




Constants
---------



  * WRAPPED_CLASSES

  * MODELS_FOR_LABELS_CACHE

  * MODELS_TO_RELOAD



Files
-----



  * `lib/neo4j/active_node/labels.rb:4 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/labels.rb#L4>`_

  * `lib/neo4j/active_node/labels/reloading.rb:1 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/labels/reloading.rb#L1>`_





Methods
-------



.. _`Neo4j/ActiveNode/Labels._wrapped_classes`:

**._wrapped_classes**
  

  .. code-block:: ruby

     def self._wrapped_classes
       Neo4j::ActiveNode::Labels::WRAPPED_CLASSES
     end



.. _`Neo4j/ActiveNode/Labels#add_label`:

**#add_label**
  adds one or more labels

  .. code-block:: ruby

     def add_label(*label)
       @_persisted_obj.add_label(*label)
     end



.. _`Neo4j/ActiveNode/Labels.add_wrapped_class`:

**.add_wrapped_class**
  

  .. code-block:: ruby

     def self.add_wrapped_class(model)
       _wrapped_classes << model
     end



.. _`Neo4j/ActiveNode/Labels.clear_model_for_label_cache`:

**.clear_model_for_label_cache**
  

  .. code-block:: ruby

     def self.clear_model_for_label_cache
       MODELS_FOR_LABELS_CACHE.clear
     end



.. _`Neo4j/ActiveNode/Labels.clear_wrapped_models`:

**.clear_wrapped_models**
  

  .. code-block:: ruby

     def self.clear_wrapped_models
       WRAPPED_CLASSES.clear
     end



.. _`Neo4j/ActiveNode/Labels#labels`:

**#labels**
  

  .. code-block:: ruby

     def labels
       @_persisted_obj.labels
     end



.. _`Neo4j/ActiveNode/Labels.model_cache`:

**.model_cache**
  

  .. code-block:: ruby

     def self.model_cache(labels)
       models = WRAPPED_CLASSES.select do |model|
         (model.mapped_label_names - labels).size == 0
       end
     
       MODELS_FOR_LABELS_CACHE[labels] = models.max do |model|
         (model.mapped_label_names & labels).size
       end
     end



.. _`Neo4j/ActiveNode/Labels.model_for_labels`:

**.model_for_labels**
  

  .. code-block:: ruby

     def self.model_for_labels(labels)
       MODELS_FOR_LABELS_CACHE[labels] || model_cache(labels)
     end



.. _`Neo4j/ActiveNode/Labels#remove_label`:

**#remove_label**
  Removes one or more labels
  Be careful, don't remove the label representing the Ruby class.

  .. code-block:: ruby

     def remove_label(*label)
       @_persisted_obj.remove_label(*label)
     end





