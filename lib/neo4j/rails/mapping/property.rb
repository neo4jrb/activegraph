module Neo4j
  module Rails
    module Mapping
      module Property
        extend ActiveSupport::Concern

        module ClassMethods

          # Create two new methods: rel_name and rel_name_rels
          # The first one returns an Neo4j::Rails::Relationships::NodesDSL
          # the second generate method (with the _rels postfix) returns a
          # Neo4j::Rails::Relationships::RelsDSL
          #
          # See also Neo4j::NodeMixin#has_n which only work with persisted relationships.
          #
          def has_n(*args)
            options = args.extract_options!
            define_has_n_methods_for(args.first, options)
          end

          # See #has_n
          def has_one(*args)
            options = args.extract_options!
            define_has_one_methods_for(args.first, options)
          end

          # Returns all defined properties
          def columns
            self._decl_props.keys
          end

          def define_has_one_methods_for(rel_type, options) #:nodoc:
            unless method_defined?(rel_type)
              class_eval <<-RUBY, __FILE__, __LINE__
                def #{rel_type}
                    dsl = _decl_rels_for(:'#{rel_type}')
                    storage = _create_or_get_storage_for_decl_rels(dsl)
                    storage.single_node(dsl.dir)
                end
              RUBY
            end

            unless method_defined?("#{rel_type}_rel")
              class_eval <<-RUBY, __FILE__, __LINE__
                def #{rel_type}_rel
                    dsl = _decl_rels_for(:'#{rel_type}')
                    storage = _create_or_get_storage_for_decl_rels(dsl)
                    storage.single_relationship(dsl.dir)
                end
              RUBY
            end

            unless method_defined?("#{rel_type}=".to_sym)
              class_eval <<-RUBY, __FILE__, __LINE__
                def #{rel_type}=(other)
                    dsl = _decl_rels_for(:'#{rel_type}')
                    storage = _create_or_get_storage_for_decl_rels(dsl)
                    storage.destroy_single_relationship(dsl.dir)
                    storage.create_relationship_to(other, dsl.dir)
                end
              RUBY
            end
            _decl_rels[rel_type.to_sym] = Neo4j::HasN::DeclRelationshipDsl.new(rel_type, true, self)
          end

          def define_has_n_methods_for(rel_type, options) #:nodoc:
            unless method_defined?(rel_type)
              class_eval <<-RUBY, __FILE__, __LINE__
                def #{rel_type}
                    dsl = _decl_rels_for(:'#{rel_type}')
                    storage = _create_or_get_storage_for_decl_rels(dsl)
                    NodesDSL.new(storage, dsl.dir)
                end
              RUBY
            end

            unless method_defined?("#{rel_type}=".to_sym)

              # TODO: This is a temporary fix for allowing running neo4j with Formtastic, issue 109
              # A better solution might be to implement accept_ids for has_n relationship and
              # make sure (somehow) that Formtastic uses the _ids methods.

              class_eval <<-RUBY, __FILE__, __LINE__
                def #{rel_type}=(nodes)
                    if nodes.is_a?(Array) && nodes.first.is_a?(String)
                      if nodes.first.blank?
                        self.#{rel_type}_rels.destroy_all
                        nodes.shift
                      end
                    else
                      self.#{rel_type}_rels.destroy_all
                    end
                    association = self.#{rel_type}
                    nodes.each { |node| association << node }
                end
              RUBY
            end

            unless method_defined?("#{rel_type}_rels".to_sym)
              class_eval <<-RUBY, __FILE__, __LINE__
                def #{rel_type}_rels
                    dsl = _decl_rels_for(:'#{rel_type}')
                    storage = _create_or_get_storage_for_decl_rels(dsl)
                  RelsDSL.new(storage, dsl.dir)
                end
              RUBY
            end

            instance_eval <<-RUBY, __FILE__, __LINE__
              def #{rel_type}
                _decl_rels[:'#{rel_type}'].rel_type.to_s
              end
            RUBY

            _decl_rels[rel_type.to_sym] = Neo4j::HasN::DeclRelationshipDsl.new(rel_type, false, self)
          end

          # Handles options for the property
          #
          # Set the property type         :type => Time
          # Set a default                  :default => "default"
          # Property must be there        :null => false
          # Property has a length limit    :limit => 128
          def property(*args)
            options = args.extract_options!
            args.each do |property_sym|
              property_setup(property_sym, options)
            end
          end

          protected
          def property_setup(property, options)
            _decl_props[property] = options
            handle_property_options_for(property, options)
            define_property_methods_for(property, options)
            define_property_before_type_cast_methods_for(property, options)
          end

          def handle_property_options_for(property, options)
            attribute_defaults[property.to_s] = options[:default] if options.has_key?(:default)

            if options.has_key?(:null) && options[:null] === false
              validates(property, :non_nil => true, :on => :create)
              validates(property, :non_nil => true, :on => :update)
            end
            validates(property, :length => { :maximum => options[:limit] }) if options[:limit]
          end

          def define_property_methods_for(property, options)
            unless method_defined?(property)
              class_eval <<-RUBY, __FILE__, __LINE__
                def #{property}
                  send(:[], "#{property}")
                end
              RUBY
            end

            unless method_defined?("#{property}=".to_sym)
              class_eval <<-RUBY, __FILE__, __LINE__
                def #{property}=(value)
                  send(:[]=, "#{property}", value)
                end
              RUBY
            end
          end

          def define_property_before_type_cast_methods_for(property, options)
            property_before_type_cast = "#{property}_before_type_cast"
            class_eval <<-RUBY, __FILE__, __LINE__
              def #{property_before_type_cast}=(value)
                @properties_before_type_cast[:#{property}]=value
              end

              def #{property_before_type_cast}
                @properties_before_type_cast.has_key?(:#{property}) ? @properties_before_type_cast[:#{property}] : self.#{property}
              end
            RUBY
          end
        end
      end
    end
  end
end
