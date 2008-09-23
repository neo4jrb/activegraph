# 
# Helper methods for specs
#

require 'fileutils'  

def delete_db
  FileUtils.rm_r Neo4j::NEO_STORAGE           if File.directory? Neo4j::NEO_STORAGE
  FileUtils.rm_r Neo4j::LUCENE_INDEX_STORAGE  if File.directory? Neo4j::LUCENE_INDEX_STORAGE
end


def start
  delete_db
  Neo4j::Neo.instance.start
end


def stop
  Neo4j::Neo.instance.stop
  delete_db
end


def undefine_class(clazz_sym)
  Object.instance_eval do 
    begin 
      remove_const clazz_sym
    end if const_defined? clazz_sym
  end
end

module Neo4j
  class BaseNode
    include Node
    include DynamicAccessor
  end
  
end