unless Module.method_defined? :cattr_accessor
  require 'active_support/core_ext/module/attribute_accessors'

  class Module
    alias :cattr_reader :mattr_reader
    alias :cattr_writer :mattr_writer
    alias :cattr_accessor :mattr_accessor
  end
end

