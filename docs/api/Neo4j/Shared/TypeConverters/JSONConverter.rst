JSONConverter
=============




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/type_converters.rb:94 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/type_converters.rb#L94>`_





Methods
-------


**#convert_type**
  

  .. hidden-code-block:: ruby

     def convert_type
       JSON
     end


**#to_db**
  

  .. hidden-code-block:: ruby

     def to_db(value)
       value.to_json
     end


**#to_ruby**
  

  .. hidden-code-block:: ruby

     def to_ruby(value)
       JSON.parse(value, quirks_mode: true)
     end





