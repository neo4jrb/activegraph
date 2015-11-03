Paginated
=========






.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   

   

   

   




Constants
---------





Files
-----



  * `lib/neo4j/paginated.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/paginated.rb#L2>`_





Methods
-------



.. _`Neo4j/Paginated.create_from`:

**.create_from**
  

  .. code-block:: ruby

     def self.create_from(source, page, per_page, order = nil)
       target = source.node_var || source.identity
       partial = source.skip((page - 1) * per_page).limit(per_page)
       ordered_partial, ordered_source = if order
                                           [partial.order_by(order), source.query.with("#{target} as #{target}").pluck("COUNT(#{target})").first]
                                         else
                                           [partial, source.count]
                                         end
       Paginated.new(ordered_partial, ordered_source, page)
     end



.. _`Neo4j/Paginated#current_page`:

**#current_page**
  Returns the value of attribute current_page

  .. code-block:: ruby

     def current_page
       @current_page
     end



.. _`Neo4j/Paginated#initialize`:

**#initialize**
  

  .. code-block:: ruby

     def initialize(items, total, current_page)
       @items = items
       @total = total
       @current_page = current_page
     end



.. _`Neo4j/Paginated#items`:

**#items**
  Returns the value of attribute items

  .. code-block:: ruby

     def items
       @items
     end



.. _`Neo4j/Paginated#total`:

**#total**
  Returns the value of attribute total

  .. code-block:: ruby

     def total
       @total
     end





