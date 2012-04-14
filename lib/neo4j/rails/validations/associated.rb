module Neo4j
  module Rails
    module Validations
      class AssociatedValidator < ActiveModel::EachValidator
        def validate_each(record, attribute, value)
          return if (value.is_a?(Enumerable) ? value : [value]).collect { |r| r.nil? || r.valid? }.all?
          record.errors.add(attribute, :invalid, options.merge(:value => value))
        end
      end

      module ClassMethods
        # Validates whether the associated object or objects are all valid themselves. Works with any kind of association.
        #
        #   class Book < Neo4j::Rails::Model
        #     has_n :pages
        #     belongs_to :library
        #
        #     validates_associated :pages, :library
        #   end
        #
        # Warning: If, after the above definition, you then wrote:
        #
        #   class Page < Neo4j::Rails::Model
        #     has_n(:book).from(:pages)
        #
        #     validates_associated :book
        #   end
        #
        # this would specify a circular dependency and cause infinite recursion.
        #
        # NOTE: This validation will not fail if the association hasn't been assigned. If you want to
        # ensure that the association is both present and guaranteed to be valid, you also need to
        # use +validates_presence_of+.
        #
        # Configuration options:
        # * <tt>:message</tt> - A custom error message (default is: "is invalid")
        # * <tt>:on</tt> - Specifies when this validation is active (default is <tt>:save</tt>, other options <tt>:create</tt>, <tt>:update</tt>).
        # * <tt>:if</tt> - Specifies a method, proc or string to call to determine if the validation should
        #   occur (e.g. <tt>:if => :allow_validation</tt>, or <tt>:if => Proc.new { |user| user.signup_step > 2 }</tt>).  The
        #   method, proc or string should return or evaluate to a true or false value.
        # * <tt>:unless</tt> - Specifies a method, proc or string to call to determine if the validation should
        #   not occur (e.g. <tt>:unless => :skip_validation</tt>, or <tt>:unless => Proc.new { |user| user.signup_step <= 2 }</tt>).  The
        #   method, proc or string should return or evaluate to a true or false value.
        def validates_associated(*attr_names)
          validates_with AssociatedValidator, _merge_attributes(attr_names)
          rel_attr_names = attr_names.collect{|a| a.is_a?(Symbol) && _decl_rels[a].has_one? ? "#{a}_rel" : a}
          rel_attr_names = rel_attr_names.collect{|a| a.is_a?(Symbol) && _decl_rels[a].has_n? ? "#{a}_rels" : a}
          validates_with AssociatedValidator, _merge_attributes(rel_attr_names)
        end
      end
    end
  end
end