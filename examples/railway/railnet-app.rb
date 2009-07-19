require 'rubygems'
require 'neo4j'

def select_station(id)
 station = nil
 Neo4j::Transaction.run do
   station = Neo4j.load(id)
   puts "You arrived at station #{station[:name]}"
 end
 return station
end

def list_trains(station)
 Neo4j::Transaction.run do
   station.relationships.outgoing.each do |rel|
     puts "Train #{rel[:train]}: departure: #{rel[:dep]}"
   end
 end
end

def train_path(station, train)
 Neo4j::Transaction.run do
   station.traverse.outgoing(train).depth(:all).each do |station|
     rel = station.relationship(train, dir = :incoming)
     puts "#{rel.start_node[:name]} ##{rel.start_node.neo_node_id}" +
       " (departure: #{rel[:dep]})" +
       " - #{rel.end_node[:name]} ##{rel.end_node.neo_node_id}" +
       " (arrival: #{rel[:arr]})"
   end;
 end;
end