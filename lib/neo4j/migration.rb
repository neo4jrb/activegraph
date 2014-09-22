module Neo4j
  class Migration
    class AddIdProperty < Neo4j::Migration
      attr_reader :models_filename

      def initialize
        @models_filename = File.join(Rails.root.join('db', 'neo4j-migrate'), 'add_id_property.yml')
      end

      def migrate
        models = ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file(models_filename))[:models]
        puts "This task will add an ID Property every node in the given file."
        puts "It may take a significant amount of time, please be patient."
        models.each do |model|
          puts
          puts
          puts "Adding IDs to #{model}"
          add_ids_to model.constantize
        end
      end

      def setup
        FileUtils.mkdir_p("db/neo4j-migrate")
        unless File.file?(models_filename)
          File.open(models_filename, 'w') do |file|
            file.write("# Provide models to which IDs should be added.\n# It will only modify nodes that do not have IDs. There is no danger of overwriting data.\n# models: [Student,Lesson,Teacher,Exam]\nmodels: []")
          end
        end
      end

      private

      def add_ids_to(model)
        require 'benchmark'

        max_per_batch = (ENV['MAX_PER_BATCH'] || default_max_per_batch).to_i

        label = model.mapped_label_name
        property = model.primary_key
        nodes_left = 1
        last_time_taken = nil

        until nodes_left == 0
          nodes_left = Neo4j::Session.query.match(n: label).where("NOT has(n.#{property})").return("COUNT(n) AS ids").first.ids

          time_per_node = last_time_taken / max_per_batch if last_time_taken
          print "Running first batch...\r"
          if time_per_node
            eta_seconds = (nodes_left * time_per_node).round
            print "#{nodes_left} nodes left.  Last batch: #{(time_per_node * 1000.0).round(1)}ms / node (ETA: #{eta_seconds / 60} minutes)\r"
          end

          return if nodes_left == 0
          to_set = [nodes_left, max_per_batch].min

          new_ids = to_set.times.map { new_id_for(model) }
          begin
            last_time_taken = Benchmark.realtime do
              Neo4j::Session.query("MATCH (n:`#{label}`) WHERE NOT has(n.#{property})
                with COLLECT(n) as nodes, {new_ids} as ids
                FOREACH(i in range(0,#{to_set - 1})| 
                  FOREACH(node in [nodes[i]]|
                    SET node.#{property} = ids[i]))
                RETURN distinct(true)
                LIMIT #{to_set}", new_ids: new_ids)
            end
          rescue Neo4j::Server::CypherResponse::ResponseError, Faraday::TimeoutError
            new_max_per_batch = (max_per_batch * 0.8).round
            puts "Error querying #{max_per_batch} nodes.  Trying #{new_max_per_batch}"
            max_per_batch = new_max_per_batch
          end
        end
      end

      def default_max_per_batch
        900
      end

      def new_id_for(model)
        if model.id_property_info[:type][:auto]
          SecureRandom::uuid
        else
          model.new.send(model.id_property_info[:type][:on])
        end
      end
    end
  end
end
