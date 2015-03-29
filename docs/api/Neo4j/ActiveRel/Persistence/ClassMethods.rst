ClassMethods
============




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   




Constants
---------





Files
-----



  * lib/neo4j/active_rel/persistence.rb:32





Methods
-------


**#create**
  Creates a new relationship between objects

  .. hidden-code-block:: ruby

     def create(props = {})
       relationship_props = extract_association_attributes!(props) || {}
       new(props).tap do |obj|
         relationship_props.each do |prop, value|
           obj.send("#{prop}=", value)
         end
         obj.save
       end
     end


**#create!**
  Same as #create, but raises an error if there is a problem during save.

  .. hidden-code-block:: ruby

     def create!(*args)
       fail RelInvalidError, self unless create(*args)
     end





