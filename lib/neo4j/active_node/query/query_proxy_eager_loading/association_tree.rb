module Neo4j
  module ActiveNode
    module Query
      module QueryProxyEagerLoading
        class AssociationTree < Hash
          attr_accessor :model, :name, :association, :path, :rel_length

          def initialize(model, name = nil, rel_length = nil)
            super()
            self.model = name ? target_class(model, name) : model
            self.name = name
            self.association = name ? model.associations[name] : nil
            self.rel_length = rel_length
          end

          def clone
            super.tap { |copy| copy.each { |key, value| copy[key] = value.clone } }
          end

          def add_spec(spec)
            fail_spec(spec) unless model

            case spec
            when nil
              nil
            when Array
              spec.each(&method(:add_spec))
            when Hash
              process_hash(spec)
            when String
              process_string(spec)
            else
              add_key(spec)
            end
          end

          def fail_spec(spec)
            fail "Cannot eager load \"past\" a polymorphic association. \
              (Since the association can return multiple models, we don't how to handle the \"#{spec}\" association.)"
          end

          def paths(*prefix)
            values.flat_map { |v| [[*prefix, v]] + v.paths(*prefix, v) }
          end

          def process_hash(spec)
            spec.each { |key, value| add_nested(key, value) }
          end

          def add_key(key, length = nil)
            self[key] ||= self.class.new(model, key, length)
          end

          def add_nested(key, value, length = nil)
            add_key(key, length).add_spec(value)
          end

          def process_string(str)
            head, rest = str.split('.', 2)
            k, length = head.split('*', -2)
            add_nested(k.to_sym, rest, length)
          end

          private

          def target_class(model, key)
            association = model.associations[key]
            fail "Invalid association: #{[*path, key].join('.')}" unless association
            model.associations[key].target_class
          end
        end
      end
    end
  end
end
