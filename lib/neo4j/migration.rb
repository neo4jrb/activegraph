require 'benchmark'

module Neo4j
  class Migration
    def migrate
      fail 'not implemented'
    end

    def output(string = '')
      puts string unless !!ENV['MIGRATIONS_SILENCED']
    end

    def print_output(string)
      print string unless !!ENV['MIGRATIONS_SILENCED']
    end

    def default_path
      Rails.root if defined? Rails
    end

    def joined_path(path)
      File.join(path.to_s, 'db', 'neo4j-migrate')
    end

    def setup
      FileUtils.mkdir_p('db/neo4j-migrate')
    end

    class AddIdProperty < Neo4j::Migration
      include Neo4j::Migrations::Helpers::IdProperty

      attr_reader :models_filename

      def initialize(path = default_path)
        @models_filename = File.join(joined_path(path), 'add_id_property.yml')
      end

      def migrate
        ActiveSupport::Deprecation.warn '`AddIdProperty` task is deprecated and may be removed from future releases. '\
                                        'Create a new migration and use the `populate_id_property` helper.', caller
        models = ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file(models_filename))[:models]
        output 'This task will add an ID Property every node in the given file.'
        output 'It may take a significant amount of time, please be patient.'
        models.each do |model|
          output
          output
          output "Adding IDs to #{model}"
          populate_id_property model
        end
      end

      delegate :query, to: Neo4j::Session

      def setup
        super
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
    end

    class RelabelRelationships < Neo4j::Migration
      attr_accessor :relationships_filename, :old_format, :new_format

      def initialize(path = default_path)
        @relationships_filename = File.join(joined_path(path), 'relabel_relationships.yml')
      end

      MESSAGE = <<MESSAGE
# Provide relationships which should be relabled.
# relationships: [students,lessons,teachers,exams]\nrelationships: []
# Provide old and new label formats:
# Allowed options are lower_hashtag, lower, or upper
formats:\n  old: lower_hashtag\n  new: lower
MESSAGE

      def setup
        super
        return if File.file?(relationships_filename)
        File.open(relationships_filename, 'w') { |f| f.write(MESSAGE) }
      end

      def migrate
        config        = YAML.load_file(relationships_filename).to_hash
        relationships = config['relationships']
        @old_format   = config['formats']['old']
        @new_format   = config['formats']['new']

        output 'This task will relabel every given relationship.'
        output 'It may take a significant amount of time, please be patient.'
        relationships.each { |relationship| reindex relationship }
      end

      private

      def count(relationship)
        Neo4j::Session.query(
          "MATCH (a)-[r:#{style(relationship, :old)}]->(b) RETURN COUNT(r)"
        ).to_a[0]['COUNT(r)']
      end

      def reindex(relationship)
        count = count(relationship)
        output "Indexing #{count} #{style(relationship, :old)}s into #{style(relationship, :new)}..."
        while count > 0
          Neo4j::Session.query(
            "MATCH (a)-[r:#{style(relationship, :old)}]->(b) CREATE (a)-[r2:#{style(relationship, :new)}]->(b) SET r2 = r WITH r LIMIT 1000 DELETE r"
          )
          count = count(relationship)
          if count > 0
            output "... #{count} #{style(relationship, :old)}'s left to go.."
          end
        end
      end

      def style(relationship, old_or_new)
        case (old_or_new == :old ? old_format : new_format)
        when 'lower_hashtag' then "`##{relationship.downcase}`"
        when 'lower'         then "`#{relationship.downcase}`"
        when 'upper'         then "`#{relationship.upcase}`"
        end
      end
    end
  end
end
