ActiveModel
===========




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   




Constants
---------





Files
-----



  * `lib/rails/generators/neo4j_generator.rb:17 <https://github.com/neo4jrb/neo4j/blob/master/lib/rails/generators/neo4j_generator.rb#L17>`_





Methods
-------


.. _ActiveModel_all:

**.all**
  

  .. hidden-code-block:: ruby

     def self.all(klass)
       "#{klass}.all"
     end


.. _ActiveModel_build:

**.build**
  

  .. hidden-code-block:: ruby

     def self.build(klass, params = nil)
       if params
         "#{klass}.new(#{params})"
       else
         "#{klass}.new"
       end
     end


.. _ActiveModel_destroy:

**#destroy**
  

  .. hidden-code-block:: ruby

     def destroy
       "#{name}.destroy"
     end


.. _ActiveModel_errors:

**#errors**
  

  .. hidden-code-block:: ruby

     def errors
       "#{name}.errors"
     end


.. _ActiveModel_find:

**.find**
  

  .. hidden-code-block:: ruby

     def self.find(klass, params = nil)
       "#{klass}.find(#{params})"
     end


.. _ActiveModel_save:

**#save**
  

  .. hidden-code-block:: ruby

     def save
       "#{name}.save"
     end


.. _ActiveModel_update_attributes:

**#update_attributes**
  

  .. hidden-code-block:: ruby

     def update_attributes(params = nil)
       "#{name}.update_attributes(#{params})"
     end





