Configuration
=============


.. glossary::

  .. _configuration-class_name_property:

  **class_name_property**
    **Default:** ``:_classname``

    Which property should be used to determine the `ActiveNode` class to wrap the node in

    If there is no value for this property on a node the node`s labels will be used to determine the `ActiveNode` class

    .. seealso:: :ref:`activenode-wrapping`
    
  **include_root_in_json**
    **Default:** ``true``

    When serializing ``ActiveNode`` and ``ActiveRel`` objects, should there be a root in the JSON of the model name.
    
    .. seealso:: http://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html
