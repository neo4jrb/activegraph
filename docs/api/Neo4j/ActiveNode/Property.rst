Property
========




.. toctree::
   :maxdepth: 3
   :titlesonly:


   

   Property/ClassMethods




Constants
---------



  * ILLEGAL_PROPS



Files
-----



  * `lib/neo4j/active_node/property.rb:2 <https://github.com/neo4jrb/neo4j/blob/master/lib/neo4j/active_node/property.rb#L2>`_





Methods
-------


.. _Property_[]:

**#[]**
  Returning nil when we get ActiveAttr::UnknownAttributeError from ActiveAttr

  .. hidden-code-block:: ruby

     def read_attribute(name)
       super(name)
     rescue ActiveAttr::UnknownAttributeError
       nil
     end


.. _Property__persisted_obj:

**#_persisted_obj**
  Returns the value of attribute _persisted_obj

  .. hidden-code-block:: ruby

     def _persisted_obj
       @_persisted_obj
     end


.. _Property_default_properties:

**#default_properties**
  

  .. hidden-code-block:: ruby

     def default_properties
       @default_properties ||= Hash.new(nil)
       # keys = self.class.default_properties.keys
       # _persisted_obj.props.reject{|key| !keys.include?(key)}
     end


.. _Property_default_properties=:

**#default_properties=**
  

  .. hidden-code-block:: ruby

     def default_properties=(properties)
       keys = self.class.default_properties.keys
       @default_properties = properties.select { |key| keys.include?(key) }
     end


.. _Property_default_property:

**#default_property**
  

  .. hidden-code-block:: ruby

     def default_property(key)
       default_properties[key.to_sym]
     end


.. _Property_initialize:

**#initialize**
  

  .. hidden-code-block:: ruby

     def initialize(attributes = {}, options = {})
       super(attributes, options)
     
       send_props(@relationship_props) if persisted? && !@relationship_props.nil?
     end


.. _Property_read_attribute:

**#read_attribute**
  Returning nil when we get ActiveAttr::UnknownAttributeError from ActiveAttr

  .. hidden-code-block:: ruby

     def read_attribute(name)
       super(name)
     rescue ActiveAttr::UnknownAttributeError
       nil
     end


.. _Property_send_props:

**#send_props**
  

  .. hidden-code-block:: ruby

     def send_props(hash)
       hash.each { |key, value| self.send("#{key}=", value) }
     end





