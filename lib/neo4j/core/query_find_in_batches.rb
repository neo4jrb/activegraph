module Neo4j
  module Core
    module QueryFindInBatches
      def find_in_batches(node_var, prop_var, options = {})
        validate_find_in_batches_options!(options)

        batch_size = options.delete(:batch_size) || 1000

        query = reorder(node_var => prop_var).limit(batch_size)

        records = query.to_a

        while records.any?
          records_size = records.size
          primary_key_offset = primary_key_offset(records.last, node_var, prop_var)

          yield records

          break if records_size < batch_size

          primary_key_var = Neo4j::Core::QueryClauses::Clause.from_key_and_single_value(node_var, prop_var)
          records = query.where("#{primary_key_var} > {primary_key_offset}")
                         .params(primary_key_offset: primary_key_offset).to_a
        end
      end

      def find_each(*args, &block)
        find_in_batches(*args) { |batch| batch.each(&block) }
      end

      private

      def validate_find_in_batches_options!(options)
        invalid_keys = options.keys.map(&:to_sym) - [:batch_size]
        fail ArgumentError, "Invalid keys: #{invalid_keys.join(', ')}" if not invalid_keys.empty?
      end

      def primary_key_offset(last_record, node_var, prop_var)
        last_record.send(node_var).send(prop_var)
      rescue NoMethodError
        begin
          last_record.send(node_var).properties[prop_var.to_sym]
        rescue NoMethodError
          last_record.send("#{node_var}.#{prop_var}") # In case we're explicitly returning it
        end
      end
    end
  end
end
