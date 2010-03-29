# 
# Helper methods for specs
#
 
require 'fileutils'
require 'tmpdir'
 
# suppress all warnings
$NEO_LOGGER.level = Logger::ERROR
 
def delete_db
  # delete db on filesystem
  FileUtils.rm_rf Neo4j::Config[:storage_path]  # NEO_STORAGE
  FileUtils.rm_rf Lucene::Config[:storage_path] unless Lucene::Config[:storage_path].nil?
end
 
def reset_config
  # reset configuration
  Lucene::Config.delete_all
  
  Neo4j::Config.delete_all
  
  Neo4j::Config[:storage_path] = "db/neo"
  Lucene::Config[:storage_path] = 'db/lucene'
  Lucene::Config[:store_on_file] = true  # otherwise it will keep the lucene index in memory !
 
end
 
def start
  puts "START"
  # stop it - just in case
  stop
 
  delete_db
 
  reset_config
  Neo4j.start
end
 
 
def stop
  # make sure we finish all transactions
  Neo4j::Transaction.finish if Neo4j::Transaction.running?
  
  Neo4j.stop
 
  #delete_db
 
  reset_config
end