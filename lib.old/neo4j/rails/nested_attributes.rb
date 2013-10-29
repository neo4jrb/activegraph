module Neo4j
  module Rails
    module NestedAttributes
      extend ActiveSupport::Concern
      extend TxMethods

      def update_nested_attributes(rel_type, attr, options)
        allow_destroy, reject_if = [options[:allow_destroy], options[:reject_if]] if options
        begin
          # Check if we want to destroy not found nodes (e.g. {..., :_destroy => '1' } ?
          destroy = attr.delete(:_destroy)
          found = _find_node(rel_type, attr[:id]) || Neo4j::Rails::Model.find(attr[:id])
          if allow_destroy && destroy && destroy != '0'
            found.destroy if found
          else
            if not found
              _create_entity(rel_type, attr) #Create new node from scratch
            else
              #Create relationship to existing node in case it doesn't exist already
              _add_relationship(rel_type, found) if (not _has_relationship(rel_type, attr[:id]))
              found.update_attributes(attr)
            end
          end
        end unless reject_if?(reject_if, attr)
      end
      tx_methods :update_nested_attributes


      module ClassMethods
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

      protected

      def _create_entity(rel_type, attr)
        clazz = self.class._decl_rels[rel_type.to_sym].target_class
        _add_relationship(rel_type, clazz.new(attr))
      end

      def _add_relationship(rel_type, node)
        if respond_to?("#{rel_type}_rel")
          send("#{rel_type}=", node)
        elsif respond_to?("#{rel_type}_rels")
          has_n = send("#{rel_type}")
          has_n << node
        else
          raise "oops #{rel_type}"
        end
      end

      def _find_node(rel_type, id)
        return nil if id.nil?
        if respond_to?("#{rel_type}_rel")
          send("#{rel_type}")
        elsif respond_to?("#{rel_type}_rels")
          has_n = send("#{rel_type}")
          has_n.find { |n| n.id == id }
        else
          raise "oops #{rel_type}"
        end
      end

      def _has_relationship(rel_type, id)
        !_find_node(rel_type, id).nil?
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


    end
  end
end
