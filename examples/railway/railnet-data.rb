require 'rubygems'
require 'neo4j'

Neo4j::Transaction.run do

# Stations
alpha = Neo4j::Node.new :name => 'Alpha'
bravo = Neo4j::Node.new :name => 'Bravo'
charlie = Neo4j::Node.new :name => 'Charlie'
delta = Neo4j::Node.new :name => 'Delta'
echo = Neo4j::Node.new :name => 'Echo'
foxtrot = Neo4j::Node.new :name => 'Foxtrot'
golf = Neo4j::Node.new :name => 'Golf'
hotel = Neo4j::Node.new :name => 'Hotel'

# Train t1_ae
t1_ab = Neo4j::Relationship.new(:t1_ae, alpha, bravo)
t1_bc = Neo4j::Relationship.new(:t1_ae, bravo, charlie)
t1_cd = Neo4j::Relationship.new(:t1_ae, charlie, delta)
t1_de = Neo4j::Relationship.new(:t1_ae, delta, echo)
t1_ab[:dep] = '11:00'; t1_ab[:arr] = '11:45'; t1_ab[:train] = 't1_ae'
t1_bc[:dep] = '11:50'; t1_bc[:arr] = '12:30'; t1_bc[:train] = 't1_ae'
t1_cd[:dep] = '12:35'; t1_cd[:arr] = '13:00'; t1_cd[:train] = 't1_ae'
t1_de[:dep] = '13:05'; t1_de[:arr] = '14:00'; t1_de[:train] = 't1_ae'

# Train t2_ag
t2_af = Neo4j::Relationship.new(:t2_ag, alpha, foxtrot)
t2_fc = Neo4j::Relationship.new(:t2_ag, foxtrot, charlie)
t2_cd = Neo4j::Relationship.new(:t2_ag, charlie, delta)
t2_dg = Neo4j::Relationship.new(:t2_ag, delta, golf)
t2_af[:dep] = '13:15'; t2_af[:arr] = '13:45'; t2_af[:train] = 't2_ag'
t2_fc[:dep] = '13:50'; t2_fc[:arr] = '14:30'; t2_fc[:train] = 't2_ag'
t2_cd[:dep] = '14:35'; t2_cd[:arr] = '15:00'; t2_cd[:train] = 't2_ag'
t2_dg[:dep] = '15:05'; t2_dg[:arr] = '15:45'; t2_dg[:train] = 't2_ag'

# Train t3_gh
t3_gd = Neo4j::Relationship.new(:t3_gh, golf, delta)
t3_dh = Neo4j::Relationship.new(:t3_gh, delta, hotel)
t3_gd[:dep] = '12:30'; t3_gd[:arr] = '13:10'; t3_gd[:train] = 't3_gh'
t3_dh[:dep] = '13:15'; t3_dh[:arr] = '14:30'; t3_dh[:train] = 't3_gh'

end
