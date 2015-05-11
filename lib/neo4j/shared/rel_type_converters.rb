module Neo4j::Shared
  # This module controls changes to relationship type based on Neo4j::Config.transform_rel_type.
  # It's used whenever a rel type is automatically determined based on ActiveRel model name or
  # association type.
  module RelTypeConverters
    def decorated_rel_type(type)
      @decorated_rel_type ||= Neo4j::Shared::RelTypeConverters.decorated_rel_type(type)
    end

    class << self
      # Determines how relationship types should look when inferred based on association or ActiveRel model name.
      # With the exception of `:none`, all options will call `underscore`, so `ThisClass` becomes `this_class`, with capitalization
      # determined by the specific option passed.
      # Valid options:
      # * :upcase - `:this_class`, `ThisClass`, `thiS_claSs` (if you don't like yourself) becomes `THIS_CLASS`
      # * :downcase - same as above, only... downcased.
      # * :legacy - downcases and prepends `#`, so ThisClass becomes `#this_class`
      # * :none - uses the string version of whatever is passed with no modifications
      def rel_transformer
        @rel_transformer ||= Neo4j::Config[:transform_rel_type].nil? ? :upcase : Neo4j::Config[:transform_rel_type]
      end

      # @param [String,Symbol] type The raw string or symbol to be used as the basis of the relationship type
      # @return [String] A string that conforms to the set rel type conversion setting.
      def decorated_rel_type(type)
        type = type.to_s
        decorated_type =  case rel_transformer
                          when :upcase
                            type.underscore.upcase
                          when :downcase
                            type.underscore.downcase
                          when :legacy
                            "##{type.underscore.downcase}"
                          when :none
                            type
                          else
                            type.underscore.upcase
                          end
        decorated_type.tap { |s| s.gsub!('/', '::') if type.include?('::') }
      end
    end
  end
end
