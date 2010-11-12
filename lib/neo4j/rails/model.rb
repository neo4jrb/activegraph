module Neo4j
  module Rails
    class Model
      include Neo4j::NodeMixin
      
      include ActiveModel::Serializers::Xml
      include ActiveModel::Dirty
      include ActiveModel::MassAssignmentSecurity

      extend ActiveModel::Naming
      
      include Persistence
      include Validations
      include Callbacks
      
      include Finders						# ActiveRecord style find
      include Mapping::Property	# allows some additional options on the #property class method
      
      class_inheritable_hash :attribute_defaults
      self.attribute_defaults = {}
      
      # --------------------------------------
      # Initialize
      # --------------------------------------

      def initialize(*)
      end

      # --------------------------------------
      # Identity
      # --------------------------------------

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

      # enables ActiveModel::Dirty and Validation
      def method_missing(method_id, *args, &block)
        if !self.class.attribute_methods_generated?
          self.class.define_attribute_methods(self.class._decl_props.keys)
          # try again
          send(method_id, *args, &block)
        elsif property?(method_id)
        	send(:[], method_id)
        else
        	super
        end
      end

      def attributes=(attributes, guard_protected_attributes = true)
      	attributes = sanitize_for_mass_assignment(attributes) if guard_protected_attributes
        attributes.each { |k, v| respond_to?(k) ? send("#{k}=", v) : self[k] = v }
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

      def clear_changes
        @previously_changed = changes
        @changed_attributes.clear
      end

      def to_model
        self
      end

      def ==(other)
      	new? ? self.__id__ == other.__id__ : @_java_node == (other)
      end
      
      # --------------------------------------
      # Class Methods
      # --------------------------------------

      class << self
        # returns a value object instead of creating a new node
        def new(attributes = {})
          wrapped = self.orig_new
          value = Neo4j::Rails::Value.new(wrapped)
          wrapped.init_on_load(value)
          wrapped.send(:attributes=, attribute_defaults, false)
          wrapped.attributes = attributes
          wrapped
        end

        def transaction(&block)
          Neo4j::Rails::Transaction.run &block
        end

        def accepts_nested_attributes_for(*attr_names)
          options = attr_names.pop if attr_names[-1].is_a?(Hash)

          attr_names.each do |association_name|
            rel = self._decl_rels[association_name.to_sym]
            raise "No relationship declared with has_n or has_one with type #{association_name}" unless rel
            to_class = rel.to_class
            raise "Can't use accepts_nested_attributes_for(#{association_name}) since it has not defined which class it has a relationship to, use has_n(#{association_name}).to(MyOtherClass)" unless to_class
            type = rel.namespace_type
            has_one = rel.has_one?

            send(:define_method, "#{association_name}_attributes=") do |attributes|
              if has_one
                update_nested_attributes(type, to_class, true, attributes, options)
              else
                if attributes.is_a?(Array)
                  attributes.each do |attr|
                    update_nested_attributes(type, to_class, false, attr, options)
                  end
                else
                  attributes.each_value do |attr|
                    update_nested_attributes(type, to_class, false, attr, options)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
