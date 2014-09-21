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
        label = model.mapped_label_name
        property = model.primary_key
        total = 1

        until total == 0
          total = Neo4j::Session.query("MATCH (n:`#{label}`) WHERE NOT has(n.#{property}) RETURN COUNT(n) as ids").first.ids
          return if total == 0
          to_set = total > 900 ? 900 : total
          new_ids = [].tap do | ids_array|
                      to_set.times { ids_array.push "'#{new_id_for(model)}'" }
                    end
          Neo4j::Session.query("MATCH (n:`#{label}`) WHERE NOT has(n.#{property})
            with COLLECT(n) as nodes, [#{new_ids.join(',')}] as ids
            FOREACH(i in range(0,#{to_set - 1})| 
              FOREACH(node in [nodes[i]]|
                SET node.#{property} = ids[i]))
            RETURN distinct(true)
            limit #{to_set}")
        end
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