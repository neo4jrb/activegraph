module Neo4j

  # This is the context in which the Migrations DSL are evaluated in.
  # This class is also responsible for running the migrations.
  class Migration < Struct.new(:version, :name)
    attr_reader :up_block, :down_block, :up_migrator, :down_migrator

    # Specifies a code block which is run when the migration is upgraded.
    #
    def up(&block)
      @up_block = block
    end

    # Specifies a code block which is run when the migration is upgraded.
    #
    def down(&block)
      @down_block = block
    end

    # Specifies which fields should be indexed
    def add_index(*fields)
      @add_indexed_field = fields
    end

    # Specifies which fields indexed should be removed 
    def rm_index(*fields)
      @rm_indexed_field = fields
    end
    
    # Runs the up migration. If successful it will set the property
    # ':db_version' on the given context.
    #
    # === Parameters
    # context:: the context on which the block is evaluated in
    # meta_node:: the node on which to set the 'db_version' property
    #
    def execute_up(context, meta_node)
      Neo4j::Transaction.run do
        context.instance_eval &@up_block if @up_block
        add_index_on(context, @add_indexed_field) if @add_indexed_field
        rm_index_on(context, @rm_indexed_field) if @rm_indexed_field
        meta_node._java_node[:db_version] = version # use the raw jave node since Neo4j::Rails::Mode wraps it
      end
    end

    # Same as #execute_up but executes the down_block instead
    def execute_down(context, meta_node)
      Neo4j::Transaction.run do
        context.instance_eval &@down_block if @down_block
        add_index_on(context, @rm_indexed_field) if @rm_indexed_field
        rm_index_on(context, @add_indexed_field) if @add_indexed_field
        meta_node._java_node[:db_version] = version - 1
      end
    end

    def add_index_on(context, fields) #:nodoc:
      context.all.each do |node|
        fields.each do |field|
          node.add_index(field)
        end
      end
    end

    def rm_index_on(context, fields) #:nodoc:
      context.all.each do |node|
        fields.each do |field|
          node.rm_index(field)
        end
      end
    end


    def to_s
      "Migration version: #{version}, name: #{name}"
    end
  end

end