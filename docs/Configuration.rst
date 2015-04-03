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

  **transform_rel_type**
    **Default:** ``:upcase``

    **Available values:** ``:upcase``, ``:downcase``, ``:legacy``, ``:none``

    Determines how relationship types as specified in associations are transformed when stored in the database.  By default this is upper-case to match with Neo4j convention so if you specify an association of ``has_many :in, :posts, type: :has_post`` then the relationship type in the database will be ``HAS_POST``

    ``:legacy``
      Causes the type to be downcased and preceded by a `#`
    ``:none``
      Uses the type as specified