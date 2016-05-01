describe Neo4j::ActiveNode::Query do
  let(:session) { double('Session') }

  before(:all) do
    @prev_wrapped_classes = Neo4j::ActiveNode::Labels._wrapped_classes
    Neo4j::ActiveNode::Labels._wrapped_classes.clear

    @class_a = Class.new do
      include Neo4j::ActiveNode::Query
      def neo_id
        8724
      end

      def self.name
        'Person'
      end

      def self.neo4j_session
        Neo4j::Session.current
      end
    end
  end

  after(:all) do
    # restore
    Neo4j::ActiveNode::Labels._wrapped_classes.concat(@prev_wrapped_classes)
  end

  describe '.query_as' do
    it 'generates a basic query with labels' do
      expect(@class_a.query_as(:q).to_cypher).to eq('MATCH (q:`Person`)')
    end

    it 'includes labels when :neo_id is not present' do
      expect(@class_a.query_as(:q).to_cypher).to include('Person')
    end

    it 'can be built upon' do
      expect(@class_a.query_as(:q).match('q--p').where(p: {name: 'Brian'}).to_cypher).to eq('MATCH (q:`Person`), q--p WHERE (p.name = {p_name})')
    end
  end

  describe '#query_as' do
    it 'generates a basic query with labels' do
      expect(@class_a.new.query_as(:q).to_cypher).to eq('MATCH (q) WHERE (ID(q) = {ID_q})')
    end

    it 'can be built upon' do
      expect(@class_a.new.query_as(:q).match('(q)--(p)').return(p: :name).to_cypher).to eq('MATCH (q), (q)--(p) WHERE (ID(q) = {ID_q}) RETURN p.name')
    end

    it 'does not include labels' do
      expect(@class_a.new.query_as(:q).to_cypher).not_to include('Person')
    end
  end
end
