# 
# Helper methods for specs
#

require 'fileutils'  

DB_LOCATION = 'var/neo'

def start
  FileUtils.rm_r DB_LOCATION if File.directory?(DB_LOCATION)
  Neo4j::Neo.instance.start(DB_LOCATION)
end


def stop
  Neo4j::Neo.instance.stop
  FileUtils.rm_r DB_LOCATION if File.directory?(DB_LOCATION)
end


#
# Uses the Neo meta nodes to find all the defined classes 
# All those classes will be removed (uses ruby remove_const)
#
def remove_class_defs
  Neo4j::transaction do
  
    Neo4j::Neo.instance.meta_nodes.nodes.each do |n| 
      clazz =  n.ref_classname.to_sym
      #    puts "Remove #{n.ref_classname}" if Object.const
      Object.instance_eval do 
        begin 
          remove_const clazz 
        end if const_defined? clazz 
      end
    end
  end
end
