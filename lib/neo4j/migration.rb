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
          add_id_property model
        end
      end

      delegate :query, to: Neo4j::Session

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
    end
  end
end
