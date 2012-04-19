module Neo4j
  module Rails
    # Defines class methods, see {ClassMethods}
    module HasN
      extend ActiveSupport::Concern

      module ClassMethods

        # Create a number of methods similar to active record has_many.
        # The first one returns an {Neo4j::Rails::Relationships::NodesDSL}
        # the second generate method (with the _rels postfix) returns a
        # {Neo4j::Rails::Relationships::RelsDSL}
        #
        # See also Neo4j::NodeMixin#has_n which only work with persisted relationships.
        #
        # @example
        #   class Thing
        #     has_n(:things)
        #   end
        #
        #   t = Thing.new
        #   t.things << Thing.new << OtherClass.new
        #   t.save # saves all nodes and relationships
        #
        # @example declare a to relationship
        #  class Company
        #    has_n(:employees).to(Person)
        #  end
        #
        #  c = Company.new
        #  c.employees << Person.new << Person.new(:name => 'kalle')
        #
        # @example creates a new person and relationship
        #  c.employees.build(:name => 'sune')
        #
        # @example creates a new person and relationship and persist it
        #  c.employees.create(:name => 'sune')
        #
        # @example delete all nodes and relationships
        #  c.employees.destroy_all
        #
        # @example access the relationships and destroy them
        #  c.employees_rels.destroy_all
        #
        # @example advanced traversal, using Neo4j::Core::Traversal
        #  c._outgoing(Company.employees).outgoing(:friends).depth.each{ }
        #
        # @see Neo4j::Rails::Relationships::NodesDSL
        def has_n(*args)
          options = args.extract_options!
          define_has_n_methods_for(args.first, options)
        end

        # Declares ONE incoming or outgoing relationship
        #
        # @example
        #  class Person
        #    has_one(:friend).to(OtherClass)
        #  end
        #
        # @example
        #  person.best_friend = my_friend
        #
        # @example
        #  person.best_friend # => my_friend
        #
        # @example
        #  person.build_best_friend(:name => 'foo')
        #
        # @example
        #  person.create_best_friend(:name => 'foo')
        #
        # @example
        #  person.create_best_friend!(:name => 'foo')
        #
        # @notice when using the <tt>build_</tt> and <tt>create_</tt> methods you <b>must</b> specify a <tt>to</to> relationship as done above in the Person example
        def has_one(*args)
          options = args.extract_options!
          define_has_one_methods_for(args.first, options)
        end

        protected

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

          unless method_defined?("#{rel_type}=")
            class_eval <<-RUBY, __FILE__, __LINE__
                def #{rel_type}=(other)
                    dsl = _decl_rels_for(:'#{rel_type}')
                    storage = _create_or_get_storage_for_decl_rels(dsl)
                    storage.destroy_single_relationship(dsl.dir)
                    storage.create_relationship_to(other, dsl.dir) if other
                end
            RUBY
          end

          unless method_defined?("build_#{rel_type}".to_sym)
            class_eval <<-RUBY, __FILE__, __LINE__
                def build_#{rel_type}(attr)
                    dsl = _decl_rels_for(:'#{rel_type}')
                    storage = _create_or_get_storage_for_decl_rels(dsl)
                    NodesDSL.new(storage, dsl.dir).build(attr)
                end
            RUBY
          end

          unless method_defined?("create_#{rel_type}".to_sym)
            class_eval <<-RUBY, __FILE__, __LINE__
                def create_#{rel_type}(attr)
                    dsl = _decl_rels_for(:'#{rel_type}')
                    storage = _create_or_get_storage_for_decl_rels(dsl)
                    NodesDSL.new(storage, dsl.dir).create(attr)
                end
            RUBY
          end

          unless method_defined?("create_#{rel_type}!".to_sym)
            class_eval <<-RUBY, __FILE__, __LINE__
                def create_#{rel_type}!(attr)
                    dsl = _decl_rels_for(:'#{rel_type}')
                    storage = _create_or_get_storage_for_decl_rels(dsl)
                    NodesDSL.new(storage, dsl.dir).create!(attr)
                end
            RUBY
          end

          _decl_rels[rel_type.to_sym] = Neo4j::Wrapper::HasN::DeclRel.new(rel_type, true, self)
        end

        def define_has_n_methods_for(rel_type, options) #:nodoc:
          unless method_defined?(rel_type)
            class_eval <<-RUBY, __FILE__, __LINE__
                def #{rel_type}(cypher_hash_query = nil, &cypher_block)
                    dsl = _decl_rels_for(:'#{rel_type}')
                    if cypher_hash_query || cypher_block
                      raise "Expected a hash, can't translated to cypher where statements" if cypher_hash_query && !cypher_hash_query.is_a?(Hash)
                      Neo4j::Wrapper::HasN::Nodes.new(self, dsl, cypher_hash_query, &cypher_block)
                    else
                      storage = _create_or_get_storage_for_decl_rels(dsl)
                      NodesDSL.new(storage, dsl.dir).tap do |n|
                        Neo4j::Wrapper::HasN::Nodes.define_rule_methods_on(n, dsl)
                      end
                    end
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

          _decl_rels[rel_type.to_sym] = Neo4j::Wrapper::HasN::DeclRel.new(rel_type, false, self)
        end

      end
    end
  end
end