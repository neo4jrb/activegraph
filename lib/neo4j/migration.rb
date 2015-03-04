require 'benchmark'

module Neo4j
  class Migration
    def migrate
      fail 'not implemented'
    end

    def output(string = '')
      puts string unless !!ENV['silenced']
    end

    def print_output(string)
      print string unless !!ENV['silenced']
    end

    def default_path
      Rails.root if defined? Rails
    end

    def joined_path(path)
      File.join(path.to_s, 'db', 'neo4j-migrate')
    end

    class AddIdProperty < Neo4j::Migration
      attr_reader :models_filename

      def initialize(path = default_path)
        @models_filename = File.join(joined_path(path), 'add_id_property.yml')
      end

      def migrate
        models = ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file(models_filename))[:models]
        output 'This task will add an ID Property every node in the given file.'
        output 'It may take a significant amount of time, please be patient.'
        models.each do |model|
          output
          output
          output "Adding IDs to #{model}"
          add_ids_to model.constantize
        end
      end

      def setup
        FileUtils.mkdir_p('db/neo4j-migrate')

        return if File.file?(models_filename)

        File.open(models_filename, 'w') do |file|
          message = <<MESSAGE
# Provide models to which IDs should be added.
# # It will only modify nodes that do not have IDs. There is no danger of overwriting data.
# # models: [Student,Lesson,Teacher,Exam]\nmodels: []
MESSAGE
          file.write(message)
        end
      end

      private

      def add_ids_to(model)
        max_per_batch = (ENV['MAX_PER_BATCH'] || default_max_per_batch).to_i

        label = model.mapped_label_name
        last_time_taken = nil

        until (nodes_left = idless_count(label, model.primary_key)) == 0
          print_status(last_time_taken, max_per_batch, nodes_left)

          count = [nodes_left, max_per_batch].min
          last_time_taken = Benchmark.realtime do
            max_per_batch = id_batch_set(label, model.primary_key, count.times.map { new_id_for(model) }, count)
          end
        end
      end

      def idless_count(label, id_property)
        Neo4j::Session.query.match(n: label).where("NOT has(n.#{id_property})").pluck('COUNT(n) AS ids').first
      end

      def print_status(last_time_taken, max_per_batch, nodes_left)
        time_per_node = last_time_taken / max_per_batch if last_time_taken
        message = if time_per_node
                    eta_seconds = (nodes_left * time_per_node).round
                    "#{nodes_left} nodes left.  Last batch: #{(time_per_node * 1000.0).round(1)}ms / node (ETA: #{eta_seconds / 60} minutes)\r"
                  else
                    "Running first batch...\r"
                  end

        print_output message
      end


      def id_batch_set(label, id_property, new_ids, count)
        tx = Neo4j::Transaction.new

        Neo4j::Session.query("MATCH (n:`#{label}`) WHERE NOT has(n.#{id_property})
          with COLLECT(n) as nodes, #{new_ids} as ids
          FOREACH(i in range(0,#{count - 1})|
            FOREACH(node in [nodes[i]]|
              SET node.#{id_property} = ids[i]))
          RETURN distinct(true)
          LIMIT #{count}")

        count
      rescue Neo4j::Server::CypherResponse::ResponseError, Faraday::TimeoutError
        new_max_per_batch = (max_per_batch * 0.8).round
        output "Error querying #{max_per_batch} nodes.  Trying #{new_max_per_batch}"
        new_max_per_batch
      ensure
        tx.close
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

    class AddClassnames < Neo4j::Migration
      def initialize(path = default_path)
        @classnames_filename = 'add_classnames.yml'
        @classnames_filepath = File.join(joined_path(path), classnames_filename)
      end

      def migrate
        output 'Adding classnames. This make take some time.'
        execute(true)
      end

      def test
        output 'TESTING! No queries will be executed.'
        execute(false)
      end

      def setup
        output "Creating file #{classnames_filepath}. Please use this as the migration guide."
        FileUtils.mkdir_p('db/neo4j-migrate')

        return if File.file?(classnames_filepath)

        source = File.join(File.dirname(__FILE__), '..', '..', 'config', 'neo4j', classnames_filename)
        FileUtils.copy_file(source, classnames_filepath)
      end

      private

      attr_reader :classnames_filename, :classnames_filepath, :model_map

      def execute(migrate = false)
        file_init
        map = []
        map.push :nodes         if model_map[:nodes]
        map.push :relationships if model_map[:relationships]
        map.each do |type|
          model_map[type].each do |action, labels|
            do_classnames(action, labels, type, migrate)
          end
        end
      end

      def do_classnames(action, labels, type, migrate = false)
        method = type == :nodes ? :node_cypher : :rel_cypher
        labels.each do |label|
          output cypher = self.send(method, label, action)
          execute_cypher(cypher) if migrate
        end
      end

      def file_init
        @model_map = ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file(classnames_filepath))
      end

      def node_cypher(label, action)
        where, phrase_start = action_variables(action, 'n')
        output "#{phrase_start} _classname '#{label}' on nodes with matching label:"
        "MATCH (n:`#{label}`) #{where} SET n._classname = '#{label}' RETURN COUNT(n) as modified"
      end

      def rel_cypher(hash, action)
        label = hash[0]
        value = hash[1]
        from = value[:from]
        fail "All relationships require a 'type'" unless value[:type]

        from_cypher = from ? "(from:`#{from}`)" : '(from)'
        to = value[:to]
        to_cypher = to ? "(to:`#{to}`)" : '(to)'
        type = "[r:`#{value[:type]}`]"
        where, phrase_start = action_variables(action, 'r')
        output "#{phrase_start} _classname '#{label}' where type is '#{value[:type]}' using cypher:"
        "MATCH #{from_cypher}-#{type}->#{to_cypher} #{where} SET r._classname = '#{label}' return COUNT(r) as modified"
      end

      def execute_cypher(query_string)
        output "Modified #{Neo4j::Session.query(query_string).first.modified} records"
        output ''
      end

      def action_variables(action, identifier)
        case action
        when 'overwrite'
          ['', 'Overwriting']
        when 'add'
          ["WHERE NOT HAS(#{identifier}._classname)", 'Adding']
        else
          fail "Invalid action #{action} specified"
        end
      end
    end
  end
end
