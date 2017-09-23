require 'rails/generators/named_base'
require 'rails/generators/active_model'

module Neo4j
  module Generators #:nodoc:
  end
end

module Neo4j::Generators::MigrationHelper
  extend ActiveSupport::Concern

  def base_migration_file_name(file_name, prefix = '')
    "#{prefix}#{file_name.parameterize}"
  end

  def migration_file_name(file_name, prefix = '')
    "#{Time.now.utc.strftime('%Y%m%d%H%M%S')}_#{base_migration_file_name(file_name, prefix)}.rb"
  end

  def migration_lookup_at(dirname)
    Dir.glob("#{dirname}/[0-9]*_*.rb")
  end

  # Stolen from https://github.com/rails/rails/blob/30767f980faa2d7a0531774ddf040471db74a23b/railties/lib/rails/generators/migration.rb#L20
  def existing_migration(dirname, file_name)
    migration_lookup_at(dirname).grep(/\d+_#{file_name}.rb$/).first
  end

  # :revoke happens when task is invoked with `rails destroy model ModelName`
  def migration_template(template_name, prefix = '')
    real_file_name = case @behavior
                     when :revoke
                       existing_migration(
                         'db/neo4j/migrate',
                         base_migration_file_name(file_name, prefix)
                       )
                     else
                       migration_file_name(file_name, prefix)
                     end

    # If running with :revoke and migration doesn't exist, real_file_name = nil
    return if !real_file_name

    @migration_class_name = file_name.camelize

    # template() method is still run on revoke but it doesn't generate anything
    # other than a consol message indicating the filepath.
    # (this appears to be behavior provided by rails)
    template template_name, File.join('db/neo4j/migrate', real_file_name)

    # On revoke, we need to manually remove the file
    FileUtils.rm(real_file_name) if @behavior == :revoke
  end
end

module Neo4j::Generators::SourcePathHelper
  extend ActiveSupport::Concern

  module ClassMethods
    def source_root
      @_neo4j_source_root ||= File.expand_path(File.join(File.dirname(__FILE__),
                                                         'neo4j', generator_name, 'templates'))
    end
  end
end


class Neo4j::Generators::ActiveModel < Rails::Generators::ActiveModel #:nodoc:
  def self.all(klass)
    "#{klass}.all"
  end

  def self.find(klass, params = nil)
    "#{klass}.find(#{params})"
  end

  def self.build(klass, params = nil)
    if params
      "#{klass}.new(#{params})"
    else
      "#{klass}.new"
    end
  end

  def save
    "#{name}.save"
  end

  def update_attributes(params = nil)
    "#{name}.update_attributes(#{params})"
  end

  def errors
    "#{name}.errors"
  end

  def destroy
    "#{name}.destroy"
  end
end


module Rails
  module Generators
    class GeneratedAttribute #:nodoc:
      def type_class
        case type.to_s.downcase
        when 'any' then 'any'
        when 'datetime' then 'DateTime'
        when 'date' then 'Date'
        when 'integer', 'number', 'fixnum' then 'Integer'
        when 'float' then 'Float'
        else
          'String'
        end
      end
    end
  end
end
