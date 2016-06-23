module Neo4j
  module Migrations
    module Helpers
      module IdProperty
        extend ActiveSupport::Concern

        def populate_id_property(label)
          model = label.to_s.constantize
          max_per_batch = (ENV['MAX_PER_BATCH'] || default_max_per_batch).to_i

          last_time_taken = nil

          until (nodes_left = idless_count(label, model.primary_key)) == 0
            print_status(last_time_taken, max_per_batch, nodes_left)

            count = [nodes_left, max_per_batch].min
            last_time_taken = Benchmark.realtime do
              max_per_batch = id_batch_set(label, model.primary_key, Array.new(count) { new_id_for(model) }, count)
            end
          end
        end

        protected

        def idless_count(label, id_property)
          query.match(n: label).where("NOT EXISTS(n.#{id_property})").pluck('COUNT(n) AS ids').first
        end

        def id_batch_set(label, id_property, new_ids, count)
          tx = ActiveBase.new_transaction

          execute("MATCH (n:`#{label}`) WHERE NOT EXISTS(n.#{id_property})
            with COLLECT(n) as nodes, #{new_ids} as ids
            FOREACH(i in range(0,#{count - 1})|
              FOREACH(node in [nodes[i]]|
                SET node.#{id_property} = ids[i]))
            RETURN distinct(true)
            LIMIT #{count}")

          count
        rescue Neo4j::Server::CypherResponse::ResponseError, Faraday::TimeoutError
          new_max_per_batch = (max_per_batch * 0.8).round
          output "Error querying #{max_per_batch} nodes. Trying #{new_max_per_batch}"
          new_max_per_batch
        ensure
          tx.close
        end

        def print_status(last_time_taken, max_per_batch, nodes_left)
          time_per_node = last_time_taken / max_per_batch if last_time_taken
          message = if time_per_node
                      eta_seconds = (nodes_left * time_per_node).round
                      "#{nodes_left} nodes left.  Last batch: #{(time_per_node * 1000.0).round(1)}ms / node (ETA: #{eta_seconds / 60} minutes)"
                    else
                      'Running first batch...'
                    end

          output message
        end

        def default_max_per_batch
          900
        end

        def new_id_for(model)
          if model.id_property_info[:type][:auto]
            SecureRandom.uuid
          else
            model.new.send(model.id_property_info[:type][:on])
          end
        end
      end
    end
  end
end
