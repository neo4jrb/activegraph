$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../support")
require 'json'
require 'rspec_helper'
require 'neo4j'

Sinatra::Application.set :environment, :test


Before do
  start
end

After do
  stop
end

def createSubtree(parent, currDepth, filesPerFolder, filesize, subfolders, maxDepth)
  currDepth = currDepth + 1
  #puts 'current: ' + currDepth.to_s + '\tmax: ' + maxDepth.to_s
  if(currDepth>=maxDepth)
    return
  end
  
  for k in 1..Integer(filesPerFolder)
    file = Neo4j::Node.new
    file[:size] = filesize
    file[:name] = "#{parent[:name]}/f#{k}"
    parent.relationships.outgoing(:child) << file
  end
  for k in 1..Integer(subfolders)
    folder = Neo4j::Node.new
    folder[:name] = "#{parent[:name]}/d#{k}"
    parent.relationships.outgoing(:child) << folder
    createSubtree(folder, currDepth, filesPerFolder, filesize, subfolders, maxDepth)
  end
  
end


When /^I create a filetree with (.*) files a (.*)kb and (\w+) subfolders in each folder, (\w+) times nested$/ do |filesPerFolder,filesize, nrSubfolders, timesNested|
  size = Integer(filesize)
  Neo4j::Transaction.run do
    fileRoot = Neo4j::Node.new
    fileRoot[:name] = 'fileRoot'
    Neo4j.ref_node.relationships.outgoing(:files) << fileRoot
    #create the owning user of the top folders
    puts 'Created fileroot '
    createSubtree(fileRoot, 0, Integer(filesPerFolder), Integer(filesize), Integer(nrSubfolders), Integer(timesNested))
  end
end

Then /^the total number of nodes in the db should be greater than (\w+)$/ do |totalFiles|
  Neo4j::Transaction.run do 
    tot = Neo4j.number_of_nodes_in_use
    puts "Total number of nodes in nodespace: #{tot}" 
    tot.should > Integer(totalFiles)
    
  end
end

def calcTotalSize(folder)
  totSize = 0 
  folder.relationships.outgoing(:child).nodes.each do |node|
    if(node[:size] != nil)
      totSize+=node[:size]
    else #this is a folder
      totSize+=calcTotalSize(node)
    end
  end
  return totSize
end

#class SizeEvaluator
#  include org.neo4j.api.core.ReturnableEvaluator
#  @totalSize = 0
#  def isReturnableNode(position)
#    node = position.currentNode()
#    puts node
#    if node.hasProperty('size')
#      return true
#    else
#    end
#    false
#  end
#end

#this is about 8x faster - untweaked
def calcSizeJava(node)
  neoNode = node.internal_node
  size = 0
  child = org.neo4j.api.core.DynamicRelationshipType.withName 'child'
  traverser = neoNode.traverse(org.neo4j.api.core.Traverser::Order::DEPTH_FIRST, 
    org.neo4j.api.core.StopEvaluator::END_OF_GRAPH, 
    org.neo4j.api.core.ReturnableEvaluator::ALL, child, org.neo4j.api.core.Direction::OUTGOING )
  while traverser.hasNext()
    node = traverser.next
    if node.hasProperty('size')
      size += node.getProperty('size')
    end
  end
  size
end

Then /^the total size of one top folder files should be (\w+) kb and response time less than (.*) s$/ do |totalSize, responseTime|
  Neo4j::Transaction.run do 
    topFolder = Neo4j.ref_node.relationships.outgoing(:files).nodes.first
    startTime = Time.now
    calcTotalSize(topFolder).should == Integer(totalSize)
    rTime = Time.new-startTime
    puts "time ruby: " + (rTime).to_s
    startTime = Time.now
    calcSizeJava(topFolder).should == Integer(totalSize)
    rTime = Time.new-startTime
    puts "time java: " + (rTime).to_s
    rTime.should < Float(responseTime)
  end
end
