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

    delegate :query, to: Neo4j::Session

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
      include Neo4j::Migrations::Helpers::Relationships
      attr_accessor :relationships_filename

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
        old_format   = config['formats']['old']
        new_format   = config['formats']['new']

        output 'This task will relabel every given relationship.'
        output 'It may take a significant amount of time, please be patient.'
        change_relation_style(relationships, old_format, new_format)
      end
    end
  end
end
