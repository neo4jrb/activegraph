require 'spec_helper'


describe "cypher queries for and has_n" do
  class Monster < Neo4j::Rails::Model
    rule(:dangerous) { |m| m[:strength] > 15 }
  end

  class Dungeon < Neo4j::Rails::Model
    has_n(:monsters).to(Monster)
  end

  class Room < Neo4j::Rails::Model
    has_n(:monsters).to(Monster)
  end

  before(:all) do
    @basilisk = Monster.create(:strength => 17, :name => 'Basilisk')
    @bugbear = Monster.create(:strength => 13, :name => 'Bugbear')
    @ghost = Monster.create(:strength => 10, :name => 'Ghost')

    @treasure_room = Room.create(:name => 'Treasure Room')
    @guard_room = Room.create(:name => 'Guard Room')

    @dungeon = Dungeon.create
    @dungeon.monsters << @basilisk << @bugbear << @ghost

    @treasure_room.monsters << @basilisk
    @guard_room.monsters << @bugbear << @ghost

    @treasure_room.save
    @guard_room.save
    @dungeon.save
  end

  describe "dungeon.monsters(:name => 'Ghost', :strength => 10)" do
    it "uses cypher" do
      @dungeon.monsters(:name => 'Ghost', :strength => 10).first[:strength].should == 10
    end
  end

  describe "dungeon.monsters.query(:name => 'Ghost', :strength => 10)" do
    it "uses cypher" do
      @dungeon.monsters.query(:name => 'Ghost', :strength => 10).first[:strength].should == 10
    end
  end

  describe "dungeon.monsters{|m| m > 8}" do
    it "uses cypher" do
      @dungeon.monsters { |m| m[:strength] > 16 }.first[:strength].should == 17
    end
  end

  describe "dungeon.monsters{|m| m.incoming(Room.monsters}[:name] == 'Treasure Room'" do
    it "uses cypher" do
      @dungeon.monsters { |m| (m.incoming(Room.monsters)[:name] == 'Guard Room') & (m[:strength] > 12) }.first.should == @bugbear
      # Same as (!)
      # START n0=node(6) MATCH (n0)-[:`Dungeon#monsters`]->(default_ret),(default_ret)<-[:`Room#monsters`]-(v1) WHERE (v1.name = "Guard Room") and (default_ret.strength > 12) RETURN default_ret'
    end
  end

  describe "Monster.all.query(:strength => 17)" do
    it "uses cypher " do
      Monster.all.query(:strength => 17).first.should == @basilisk
    end

    it "can explain the cypher query as a String" do
      rule_node = Neo4j::Wrapper::Rule::Rule.rule_node_for(Monster)
      id = rule_node.rule_node.neo_id
      Monster.all.query(:strength => 17).to_s.should == "START n0=node(#{id}) MATCH (n0)-[:`_all`]->(default_ret) WHERE default_ret.strength = 17 RETURN default_ret"
    end

  end

  describe "dungeon.monsters.dangerous" do
    it "uses cypher" do
      x = @dungeon.monsters
      @dungeon.monsters.dangerous.to_a.size.should == 1
    end
  end

  describe "dungeon.monsters.dangerous{|m| m[:weapon?] == 'sword']}" do
    it "uses cypher" do
      @dungeon.monsters.dangerous { |m| m[:weapon?] == 'sword' } == 1
    end

    it "can be explained" do
      id = @dungeon.neo_id
      @dungeon.monsters.dangerous { |m| m[:weapon?] == 'sword' }.to_s.should == "START n0=node(#{id}) MATCH (n0)-[:`Dungeon#monsters`]->(default_ret),(default_ret)<-[:`dangerous`]-(v1) WHERE default_ret.weapon? = \"sword\" RETURN default_ret"
    end
  end


  describe "return a different relationship: @dungeon.monsters.dangerous { |m| rooms = m.incoming(Room.monsters); rooms} " do
    it "uses cypher" do
      # In which rooms are the dangerous monsters ?
      @dungeon.monsters.dangerous { |m| rooms = m.incoming(Room.monsters); rooms }.first.should == @treasure_room
    end
  end

end


