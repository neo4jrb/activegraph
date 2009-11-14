# 
# Helper methods for specs
#

require 'fileutils'
require 'tmpdir'

# suppress all warnings
$NEO_LOGGER.level = Logger::ERROR

NEO_STORAGE = Dir::tmpdir + "/neo_storage"
LUCENE_INDEX_LOCATION = Dir::tmpdir + "/lucene"

Lucene::Config[:storage_path] = LUCENE_INDEX_LOCATION
Lucene::Config[:store_on_file] = false
Neo4j::Config[:storage_path] = NEO_STORAGE

def delete_db
  # delete db on filesystem
  FileUtils.rm_rf Neo4j::Config[:storage_path]  # NEO_STORAGE
  FileUtils.rm_rf Lucene::Config[:storage_path] unless Lucene::Config[:storage_path].nil?
end

def reset_config
  # reset configuration
  Lucene::Config.delete_all
  Lucene::Config[:storage_path] = LUCENE_INDEX_LOCATION
  Lucene::Config[:store_on_file] = false

  Neo4j::Config.delete_all
  Neo4j::Config[:storage_path] = NEO_STORAGE
end

def start
  # stop it - just in case
  stop

  delete_db

  reset_config
  
  # start neo
  Neo4j.start
end


def stop
  # make sure we finish all transactions
  Neo4j::Transaction.finish if Neo4j::Transaction.running?
  
  Neo4j.stop

  delete_db

  reset_config
end


def undefine_class(*clazz_syms)
  clazz_syms.each do |clazz_sym|
    Object.instance_eval do
      begin
        Neo4j::Indexer.remove_instance const_get(clazz_sym)
        remove_const clazz_sym
      end if const_defined? clazz_sym
    end
  end
end


def clazz_from_symbol(classname_as_symbol)
  classname_as_symbol.to_s.split("::").inject(Kernel) do |container, name|
    container.const_get(name.to_s)
  end
end