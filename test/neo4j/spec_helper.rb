# 
# Helper methods for specs
#

require 'fileutils'
require 'tmpdir'

NEO_STORAGE = Dir::tmpdir + "/neo_storage"
LUCENE_INDEX_LOCATION = Dir::tmpdir + "/neo_lucene_storage"

def delete_db
  FileUtils.rm_rf NEO_STORAGE
  FileUtils.rm_rf LUCENE_INDEX_LOCATION
end


def start
  delete_db
  Neo4j.start NEO_STORAGE, LUCENE_INDEX_LOCATION
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
