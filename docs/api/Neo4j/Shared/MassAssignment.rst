MassAssignment
==============



MassAssignment allows you to bulk set and update attributes

Including MassAssignment into your model gives it a set of mass assignment
methods, similar to those found in ActiveRecord.

Originally part of ActiveAttr, https://github.com/cgriego/active_attr


.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared/mass_assignment.rb:13 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared/mass_assignment.rb#L13>`_





Methods
-------



.. _`Neo4j/Shared/MassAssignment#assign_attributes`:

**#assign_attributes**
  Mass update a model's attributes

  .. code-block:: ruby

     def assign_attributes(new_attributes = nil)
       return unless new_attributes.present?
       new_attributes.each do |name, value|
         writer = :"#{name}="
         send(writer, value) if respond_to?(writer)
       end
     end



.. _`Neo4j/Shared/MassAssignment#attributes=`:

**#attributes=**
  Mass update a model's attributes

  .. code-block:: ruby

     def attributes=(new_attributes)
       assign_attributes(new_attributes)
     end



.. _`Neo4j/Shared/MassAssignment#initialize`:

**#initialize**
  Initialize a model with a set of attributes

  .. code-block:: ruby

     def initialize(attributes = nil)
       assign_attributes(attributes)
       super()
     end





