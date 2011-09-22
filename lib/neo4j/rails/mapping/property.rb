module Neo4j
  module Rails
    module Mapping
      module Property
        extend ActiveSupport::Concern

        module ClassMethods

          def has_n(*args)
            options = args.extract_options!
            define_has_n_methods_for(args.first, options)
          end

          def has_one(*args)
            options = args.extract_options!
            define_has_one_methods_for(args.first, options)
          end


          def define_has_one_methods_for(rel_type, options)
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
                    rel = storage.single_relationship(dsl.dir)
                    rel && rel.destroy
                    storage.create_relationship_to(other, dsl.dir)
                end
              RUBY
            end
            _decl_rels[rel_type.to_sym] = Neo4j::HasN::DeclRelationshipDsl.new(rel_type, true, self)
          end

          def define_has_n_methods_for(rel_type, options)
            unless method_defined?(rel_type)
              class_eval <<-RUBY, __FILE__, __LINE__
                def #{rel_type}
                    dsl = _decl_rels_for(:'#{rel_type}')
                    storage = _create_or_get_storage_for_decl_rels(dsl)
                    NodesDSL.new(storage, dsl.dir)
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
          # Set the property type 				:type => Time
          # Set a default  								:default => "default"
          # Property must be there  			:null => false
          # Property has a length limit  	:limit => 128
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
							  attr_accessor :#{property}_before_type_cast

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
				end
			end
		end
	end
end
