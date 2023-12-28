module ActiveGraph::Generators::MigrationHelper
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
