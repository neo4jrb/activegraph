module Neo4j
  module Rails
    class Model
      include Neo4j::NodeMixin

      # Initialize a Node with a set of properties (or empty if nothing is passed)
      def initialize(attributes = {})
        reset_attributes
        clear_relationships
        self.attributes = attributes if attributes.is_a?(Hash)
      end

      def id
        neo_id.nil? ? nil : neo_id.to_s
      end

      def to_param
        persisted? ? neo_id.to_s : nil
      end

      # Returns an Enumerable of all (primary) key attributes
      # or nil if model.persisted? is false
      def to_key
        persisted? ? [id] : nil
      end

      def reject_if?(proc_or_symbol, attr)
        return false if proc_or_symbol.nil?
        if proc_or_symbol.is_a?(Symbol)
          meth = method(proc_or_symbol)
          meth.arity == 0 ? meth.call : meth.call(attr)
        else
          proc_or_symbol.call(attr)
        end
      end

      def to_model
        self
      end

      def ==(other)
        new? ? self.__id__ == other.__id__ : @_java_node == (other)
      end


      # --------------------------------------
      # Public Class Methods
      # --------------------------------------
      class << self
        # NodeMixin overwrites the #new class method but it saves it as orig_new
        # Here, we just get it back to normal
        alias :new :orig_new

        def transaction(&block)
          Neo4j::Rails::Transaction.run do |tx|
            block.call(tx)
          end
        end

        ##
        # Determines whether to use Time.local (using :local) or Time.utc (using :utc) when pulling
        # dates and times from the database. This is set to :local by default.
        def default_timezone
          @default_timezone || :local
        end

        def default_timezone=(zone)
          @default_timezone = zone
        end

        def accepts_nested_attributes_for(*attr_names)
          options = attr_names.pop if attr_names[-1].is_a?(Hash)

          attr_names.each do |association_name|
            # Do some validation that we have defined the relationships we want to nest
            rel = self._decl_rels[association_name.to_sym]
            raise "No relationship declared with has_n or has_one with type #{association_name}" unless rel
            raise "Can't use accepts_nested_attributes_for(#{association_name}) since it has not defined which class it has a relationship to, use has_n(#{association_name}).to(MyOtherClass)" unless rel.target_class

            if rel.has_one?
              send(:define_method, "#{association_name}_attributes=") do |attributes|
                update_nested_attributes(association_name.to_sym, attributes, options)
              end
            else
              send(:define_method, "#{association_name}_attributes=") do |attributes|
                if attributes.is_a?(Array)
                  attributes.each do |attr|
                    update_nested_attributes(association_name.to_sym, attr, options)
                  end
                else
                  attributes.each_value do |attr|
                    update_nested_attributes(association_name.to_sym, attr, options)
                  end
                end
              end
            end

          end
        end
      end
    end

    Model.class_eval do
      extend ActiveModel::Translation

      include Persistence # handles how to save, create and update the model
      include Attributes # handles how to save and retrieve attributes
      include Mapping::Property # allows some additional options on the #property class method
      include Serialization # enable to_xml and to_json
      include Timestamps # handle created_at, updated_at timestamp properties
      include Validations # enable validations
      include Callbacks # enable callbacks
      include Finders # ActiveRecord style find
      include Relationships # for none persisted relationships
    end
  end
end
