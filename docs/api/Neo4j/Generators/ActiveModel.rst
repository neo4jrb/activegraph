ActiveModel
===========




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   

   

   




Constants
---------





Files
-----



  * lib/rails/generators/neo4j_generator.rb:17





Methods
-------


**#all**
  

  .. hidden-code-block:: ruby

     def self.all(klass)
       "#{klass}.all"
     end


**#build**
  

  .. hidden-code-block:: ruby

     def self.build(klass, params = nil)
       if params
         "#{klass}.new(#{params})"
       else
         "#{klass}.new"
       end
     end


**#destroy**
  

  .. hidden-code-block:: ruby

     def destroy
       "#{name}.destroy"
     end


**#errors**
  

  .. hidden-code-block:: ruby

     def errors
       "#{name}.errors"
     end


**#find**
  

  .. hidden-code-block:: ruby

     def self.find(klass, params = nil)
       "#{klass}.find(#{params})"
     end


**#save**
  

  .. hidden-code-block:: ruby

     def save
       "#{name}.save"
     end


**#update_attributes**
  

  .. hidden-code-block:: ruby

     def update_attributes(params = nil)
       "#{name}.update_attributes(#{params})"
     end





