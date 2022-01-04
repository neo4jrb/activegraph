module ActiveGraph
  module Node
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

          def add_spec_and_validate(spec)
            add_spec(spec)
            validate_for_zero_length_paths
          end

          def validate_for_zero_length_paths
            fail 'Can not eager load more than one zero length path.' if values.count { |value| value.zero_length_path? } > 1
          end

          def zero_length_path?
            rel_length&.fetch(:min, nil)&.to_s == '0' ||
              values.any? { |value| value.zero_length_path? }
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
            map = StringParsers::RelationParser.new.parse(str)
            add_nested(map[:rel_name].to_sym, map[:rest_str].to_s.presence, map[:length_part])
          end

          private

          def target_class(model, key)
            association = model.associations[key.to_sym]
            fail "Invalid association: #{[*path, key].join('.')}" unless association
            model.associations[key].target_class
          end
        end
      end
    end
  end
end
