require 'rails/generators/named_base'
require 'rails/generators/active_model'

module Neo4j
  module Generators #:nodoc:
  end
end

class Neo4j::Generators::Base < Rails::Generators::NamedBase #:nodoc:
  def self.source_root
    @_neo4j_source_root ||= File.expand_path(File.join(File.dirname(__FILE__),
                                                       'neo4j', generator_name, 'templates'))
  end
end

class Neo4j::Generators::ActiveModel < Rails::Generators::ActiveModel #:nodoc:
  def self.all(klass)
    "#{klass}.all"
  end

  def self.find(klass, params=nil)
    "#{klass}.find(#{params})"
  end

  def self.build(klass, params=nil)
    if params
      "#{klass}.new(#{params})"
    else
      "#{klass}.new"
    end
  end

  def save
    "#{name}.save"
  end

  def update_attributes(params=nil)
    "#{name}.update_attributes(#{params})"
  end

  def errors
    "#{name}.errors"
  end

  def destroy
    "#{name}.destroy"
  end
end

module Rails
  module Generators
    class GeneratedAttribute #:nodoc:
      def type_class
        case type.to_s.downcase
          when 'any' then
            'any'
          when 'datetime' then
            'DateTime'
          when 'date' then
            'Date'
          when 'text' then
            'String'
          when 'integer', 'number', 'fixnum' then
            'Fixnum'
          when 'float' then
            'Float'
          else
            'String'
        end
      end
    end
  end
end
