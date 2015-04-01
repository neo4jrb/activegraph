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


.. _Paginated_create_from:

**.create_from**
  

  .. hidden-code-block:: ruby

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


.. _Paginated_current_page:

**#current_page**
  Returns the value of attribute current_page

  .. hidden-code-block:: ruby

     def current_page
       @current_page
     end


.. _Paginated_initialize:

**#initialize**
  

  .. hidden-code-block:: ruby

     def initialize(items, total, current_page)
       @items = items
       @total = total
       @current_page = current_page
     end


.. _Paginated_items:

**#items**
  Returns the value of attribute items

  .. hidden-code-block:: ruby

     def items
       @items
     end


.. _Paginated_total:

**#total**
  Returns the value of attribute total

  .. hidden-code-block:: ruby

     def total
       @total
     end





