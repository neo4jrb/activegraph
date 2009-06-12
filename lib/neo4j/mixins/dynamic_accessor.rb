module Neo4j
  
  # A mixin that allows to write/read any property without declaring it first.
  # Uses method_missing Ruby hook.
  #
  # :api: public
  module DynamicAccessorMixin

    # Returns the given property
    #
    # :api: public
    def [](name)
      get_property(name.to_s)
    end

    # Sets the given property to a given value
    #
    # :api: public
    def []=(name, value)
      set_property(name.to_s, value)
    end
    
    #
    # A hook used to set and get undeclared properties
    #
    def method_missing(methodname, *args)
      # allows to set and get any neo property without declaring them first
      name = methodname.to_s
      setter = /=$/ === name
      expected_args = 0
      if setter
        name = name[0...-1]
        expected_args = 1
      end
      unless args.size == expected_args
        err = "method '#{name}' on '#{self.class.to_s}' has wrong number of arguments (#{args.size} for #{expected_args})"
        raise ArgumentError.new(err)
      end

      if setter
        set_property(name, args[0])
      else
        get_property(name)
      end
    end
  end
end
