# 
# Helper methods for specs
#

require 'fileutils'
require 'tmpdir'

NEO_STORAGE = Dir::tmpdir + "/neo_storage"

def delete_db
  # make sure we finish all transactions
  Neo4j::Transaction.current.finish if Neo4j::Transaction.running?
  Lucene::Config.delete_all
  FileUtils.rm_rf NEO_STORAGE
end


def start
  delete_db
  Neo4j.start NEO_STORAGE
end


def stop
  Neo4j.stop
  delete_db
end


def undefine_class(*clazz_syms)
  clazz_syms.each do |clazz_sym|
    Object.instance_eval do
      begin
        remove_const clazz_sym
      end if const_defined? clazz_sym
    end
  end
end
