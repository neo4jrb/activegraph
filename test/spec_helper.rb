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


#
# Uses the Neo meta nodes to find all the defined classes 
# All those classes will be removed (uses ruby remove_const)
#
def remove_class_defs
  Neo4j::Neo.instance.meta_nodes.nodes.each do |n| 
    clazz =  n.ref_classname.to_sym
    Object.instance_eval do 
      begin 
        remove_const clazz 
      end if const_defined? clazz 
    end
  end
end
