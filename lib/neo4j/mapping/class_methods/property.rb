module Neo4j::Mapping
  module ClassMethods
    module Property

      # Generates accessor method and sets configuration for Neo4j node properties.
      # The generated accessor is a simple wrapper around the #[] and
      # #[]= operators.
      #
      # ==== Types
      # If a property is set to nil the property will be removed.
      # A property can be of any primitive type (Boolean, String, Fixnum, Float) and does not
      # even have to be the same.
      #
      # Example:
      #   class Foo
      #     include Neo4j::NodeMixin
      #     property :age
      #   end
      #
      # Example:
      #   foo = Foo.new
      #   foo.age = "hej" # first set it to string
      #   foo.age = 42  # change it to a Fixnum
      #
      # However, you can specify an type for the index, see Neo4j::Index::Indexer#index
      #
      # ==== Example
      #   class Baaz; end
      #
      #   class Foo
      #     include Neo4j::NodeMixin
      #     property :name, :city # can set several properties in one go
      #     property :bar
      #   end
      #
      #   f = Foo.new
      #   f.bar = Baaz.new
      #
      def property(*props)
        if props.size == 2 and props[1].kind_of?(Hash)
          props[1].each_pair do |key, value|
            pname = props[0].to_sym
            _decl_props[pname] ||= {}
            _decl_props[pname][key] = value
          end
          props = props[0..0]
        end

        props.each do |prop|
          pname = prop.to_sym
          _decl_props[pname] ||= {}

          define_method(pname) do
            # TODO inheritance, should check self.class.superclass if self.class._decl_props[pname] is nil
            # TODO refactoring and DRY
            if self.class._decl_props[pname] && self.class._decl_props[pname][:type]
              type      = self.class._decl_props[pname][:type]
              converter = Neo4j::Config[:converters][type]
              value = converter.to_ruby(self[pname]) if converter
              value || self[pname]
            else
              self[pname]
            end
          end

          name = (pname.to_s() +"=").to_sym
          define_method(name) do |value|
            # TODO inheritance, should check self.class.superclass if self.class._decl_props[pname] is nil
            # TODO refactoring and DRY
            if self.class._decl_props[pname] && self.class._decl_props[pname][:type]
              type      = self.class._decl_props[pname][:type]
              converter = Neo4j::Config[:converters][type]
              value = converter.to_java(value) if converter
            end
            self[pname] = value
          end
        end
      end


      # Returns true if the given property name has been defined with the class
      # method property or properties.
      #
      # Notice that the node may have properties that has not been declared.
      # It is always possible to set an undeclared property on a node.
      #
      # ==== Returns
      # true or false
      #
      def property?(prop_name)
        return false if _decl_props[prop_name.to_sym].nil?
        _decl_props[prop_name.to_sym][:defined] == true
      end

    end
  end
end
