YAMLConverter
=============




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/type_converters.rb:77 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/type_converters.rb#L77>`_





Methods
-------


.. _YAMLConverter_convert_type:

**.convert_type**
  

  .. hidden-code-block:: ruby

     def convert_type
       Hash
     end


.. _YAMLConverter_to_db:

**.to_db**
  

  .. hidden-code-block:: ruby

     def to_db(value)
       Psych.dump(value)
     end


.. _YAMLConverter_to_ruby:

**.to_ruby**
  

  .. hidden-code-block:: ruby

     def to_ruby(value)
       Psych.load(value)
     end





