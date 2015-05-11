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

  **module_handling**
    **Default:** ``:none``

    **Available values:** ``:demodulize``, ``:none``, ``proc``

    Determines what, if anything, should be done to module names when a model's class is set. By default, there is a direct mapping of model name to label, so `MyModule::MyClass` results in a label with the same name.

    The `:demodulize` option uses ActiveSupport's method of the same name to strip off modules. If you use a `proc`, it will the class name as an argument and you should return a string that modifies it as you see fit.

  **association_model_namespace**
    **Default:** ``nil``

    Associations defined in node models will try to match association names to classes. For example, `has_many :out, :student` will look for a `Student` class. To avoid having to use `model_class: 'MyModule::Student'`, this config option lets you specify the module that should be used globally for class name discovery.

    Of course, even with this option set, you can always override it by calling `model_class: 'ClassName'`.
