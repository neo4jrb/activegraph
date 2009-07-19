require 'rubygems'
require 'neo4j'

Neo4j::Transaction.run do

# Stations
alpha = Neo4j::Node.new; alpha[:name] = 'Alpha'
bravo = Neo4j::Node.new; bravo[:name] = 'Bravo'
charlie = Neo4j::Node.new; charlie[:name] = 'Charlie'
delta = Neo4j::Node.new; delta[:name] = 'Delta'
echo = Neo4j::Node.new; echo[:name] = 'Echo'
foxtrot = Neo4j::Node.new; foxtrot[:name] = 'Foxtrot'
golf = Neo4j::Node.new; golf[:name] = 'Golf'
hotel = Neo4j::Node.new; hotel[:name] = 'Hotel'

# Train t1_ae
t1_ab = alpha.relationships.outgoing(:t1_ae) << bravo
t1_bc = bravo.relationships.outgoing(:t1_ae) << charlie
t1_cd = charlie.relationships.outgoing(:t1_ae) << delta
t1_de = delta.relationships.outgoing(:t1_ae) << echo
t1_ab[:dep] = '11:00'; t1_ab[:arr] = '11:45'; t1_ab[:train] = 't1_ae'
t1_bc[:dep] = '11:50'; t1_bc[:arr] = '12:30'; t1_bc[:train] = 't1_ae'
t1_cd[:dep] = '12:35'; t1_cd[:arr] = '13:00'; t1_cd[:train] = 't1_ae'
t1_de[:dep] = '13:05'; t1_de[:arr] = '14:00'; t1_de[:train] = 't1_ae'

# Train t2_ag
t2_af = alpha.relationships.outgoing(:t2_ag) << foxtrot
t2_fc = foxtrot.relationships.outgoing(:t2_ag) << charlie
t2_cd = charlie.relationships.outgoing(:t2_ag) << delta
t2_dg = delta.relationships.outgoing(:t2_ag) << golf
t2_af[:dep] = '13:15'; t2_af[:arr] = '13:45'; t2_af[:train] = 't2_ag'
t2_fc[:dep] = '13:50'; t2_fc[:arr] = '14:30'; t2_fc[:train] = 't2_ag'
t2_cd[:dep] = '14:35'; t2_cd[:arr] = '15:00'; t2_cd[:train] = 't2_ag'
t2_dg[:dep] = '15:05'; t2_dg[:arr] = '15:45'; t2_dg[:train] = 't2_ag'

# Train t3_gh
t3_gd = golf.relationships.outgoing(:t3_gh) << delta
t3_dh = delta.relationships.outgoing(:t3_gh) << hotel
t3_gd[:dep] = '12:30'; t3_gd[:arr] = '13:10'; t3_gd[:train] = 't3_gh'
t3_dh[:dep] = '13:15'; t3_dh[:arr] = '14:30'; t3_dh[:train] = 't3_gh'

end
