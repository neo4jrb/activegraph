$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + "/../support")
require 'json'
require 'rspec_helper'
require 'neo4j'

Sinatra::Application.set :environment, :test


Before do
  start
  Neo4j.info
end

After do
  stop
end

def createBatchSubtree(batch_neo, parent_props, currDepth, filesPerFolder, filesize, subfolders, maxDepth)
  currDepth = currDepth + 1
  if(currDepth>=maxDepth)
    return
  end
  
  for k in 1..Integer(filesPerFolder)
    props = java.util.HashMap.new
    props.put('size',filesize)
    props.put('name',"#{parent_props[:name]}/f#{k}")
    #needed for JRuby compatibility
    props.put('classname', Neo4j::Node.to_s)
    file = batch_neo.createNode(props)
    batch_neo.createRelationship( parent_props[:id], file, org.neo4j.graphdb.DynamicRelationshipType.withName('child'), nil)
  end
  for k in 1..Integer(subfolders)
    props = java.util.HashMap.new
    props.put('name',"#{parent_props[:name]}/d#{k}")
    #needed for JRuby compatibility
    props.put('classname', Neo4j::Node.to_s)
    folder = batch_neo.createNode(props)
    batch_neo.createRelationship(parent_props[:id], folder, org.neo4j.graphdb.DynamicRelationshipType.withName('child'), nil)
    folder_props = {:name => props.get('name'),:id => folder}
    createBatchSubtree(batch_neo, folder_props, currDepth, filesPerFolder, filesize, subfolders, maxDepth)
  end
end


When /^I create a filetree with (.*) files a (.*)kb and (\w+) subfolders in each folder, (\w+) times nested$/ do |filesPerFolder,filesize, nrSubfolders, timesNested|
  size = Integer(filesize)
  fileRoot = nil
  Neo4j::Transaction.run do
    fileRoot = Neo4j::Node.new
    fileRoot[:name] = 'fileRoot'
    Neo4j.ref_node.rels.outgoing(:files) << fileRoot
    #create the owning user of the top folders
    puts 'Created fileroot '
  end
  parent_props = {:name => fileRoot[:name], :id => fileRoot._java_node.getId()}
  #stop Neo4j Embedded
  stop
  #start batch inserter to speed things up
  startTime = Time.now
  batch_neo = org.neo4j.kernel.impl.batchinsert.BatchInserterImpl.new('db/neo', org.neo4j.kernel.impl.batchinsert.BatchInserterImpl.loadProperties('batch.props'))
  createBatchSubtree(batch_neo, parent_props, 0, Integer(filesPerFolder), Integer(filesize), Integer(nrSubfolders), Integer(timesNested))
  #shut down the batchinserter
  batch_neo.shutdown
  puts "Insert time: " + (Time.now-startTime).to_s
  #start Embedded Neo4j again
  Neo4j.start
  
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
  folder.rels.outgoing(:child).nodes.each do |node|
    if(node[:size] != nil)
      totSize+=node[:size]
    else #this is a folder
      totSize+=calcTotalSize(node)
    end
  end
  return totSize
end

def calcSizeJava(node)
  neoNode = node._java_node
  size = 0
  child = org.neo4j.graphdb.DynamicRelationshipType.withName 'child'
  traverser = neoNode.traverse(org.neo4j.graphdb.Traverser::Order::DEPTH_FIRST, 
    org.neo4j.graphdb.StopEvaluator::END_OF_GRAPH, 
    org.neo4j.graphdb.ReturnableEvaluator::ALL, child, org.neo4j.graphdb.Direction::OUTGOING )
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
    topFolder = Neo4j.ref_node.rels.outgoing(:files).nodes.first
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
