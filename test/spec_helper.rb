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


