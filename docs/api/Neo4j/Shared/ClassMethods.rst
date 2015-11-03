ClassMethods
============






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/shared.rb:10 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/shared.rb#L10>`_





Methods
-------



.. _`Neo4j/Shared/ClassMethods#neo4j_session`:

**#neo4j_session**
  

  .. code-block:: ruby

     def neo4j_session
       if @neo4j_session_name
         Neo4j::Session.named(@neo4j_session_name) ||
           fail("#{self.name} is configured to use a neo4j session named #{@neo4j_session_name}, but no such session is registered with Neo4j::Session")
       else
         Neo4j::Session.current!
       end
     end



.. _`Neo4j/Shared/ClassMethods#neo4j_session_name`:

**#neo4j_session_name**
  

  .. code-block:: ruby

     def neo4j_session_name(name)
       ActiveSupport::Deprecation.warn 'neo4j_session_name is deprecated and may be removed from future releases, use neo4j_session_name= instead.', caller
     
       @neo4j_session_name = name
     end



.. _`Neo4j/Shared/ClassMethods#neo4j_session_name=`:

**#neo4j_session_name=**
  Sets the attribute neo4j_session_name

  .. code-block:: ruby

     def neo4j_session_name=(value)
       @neo4j_session_name = value
     end





