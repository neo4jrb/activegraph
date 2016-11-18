module Neo4j
  # Neo4j.rb Errors
  # Generic Neo4j.rb exception class.
  class Error < StandardError
  end

  # Raised when Neo4j.rb cannot find record by given id.
  class RecordNotFound < Error
    attr_reader :model, :primary_key, :id

    def initialize(message = nil, model = nil, primary_key = nil, id = nil)
      @primary_key = primary_key
      @model = model
      @id = id

      super(message)
    end
  end

  class DeprecatedSchemaDefinitionError < Error; end

  class InvalidPropertyOptionsError < Error; end

  class InvalidParameterError < Error; end

  class UnknownTypeConverterError < Error; end

  class DangerousAttributeError < ScriptError; end
  class UnknownAttributeError < NoMethodError; end

  class MigrationError < Error; end
  class IrreversibleMigration < MigrationError; end
  class UnknownMigrationVersionError < MigrationError; end

  # Inspired/taken from active_record/migration.rb
  class PendingMigrationError < MigrationError
    def initialize(migrations)
      pending_migrations = migrations.join("\n")
      if rails? && defined?(Rails.env)
        super("Migrations are pending:\n#{pending_migrations}\n To resolve this issue, run:\n\n        #{command_name} neo4j:migrate RAILS_ENV=#{::Rails.env}")
      else
        super("Migrations are pending:\n#{pending_migrations}\n To resolve this issue, run:\n\n        #{command_name} neo4j:migrate")
      end
    end

    private

    def command_name
      return 'rake' unless rails?
      Rails.version.to_f >= 5 ? 'bin/rails' : 'bin/rake'
    end

    def rails?
      defined?(Rails)
    end
  end
end
