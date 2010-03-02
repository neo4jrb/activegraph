Neo4j.migration 2, "Index DB" do
  up do

    puts "Migration 2, Index DB on #{Lucene::Config[:storage_path]}"

    Neo4j::Transaction.run do
      puts "Creating lucene index ..."
      Actor.index :name, :tokenized => true
      Actor.update_index
    end
    # only possible to access and query the index after the transaction commits
  end

  down do
    puts "removing lucene index"
    Actor.remove_index :name
    # Actor.update_index # maybe nicer way of deleting indexes - hmm, does it work ?
    require 'fileutils'
    FileUtils.rm_rf Lucene::Config[:storage_path] # quick and dirty way of killing the lucene index
  end
end
