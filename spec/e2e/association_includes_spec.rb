require 'spec_helper'

# The `includes` method works by preloading a node's association cache with the results of a query.
# In these tests, we demonstrate that the association cache is prepopulated with the expected results.
# We do not test the association cache itself here because it has its own tests and we trust they are working properly.
describe 'association inclusion' do
  class AISBand
    include Neo4j::ActiveNode
    property :name
    has_many :out, :members, model_class: 'AISMember', rel_class: 'AISHasMember'
  end

  class AISMember
    include Neo4j::ActiveNode
    property :name
    has_many :in, :bands, model_class: 'AISBand', rel_class: 'AISHasMember'
    has_many :out, :instruments, model_class: 'AISInstrument', rel_class: 'AISPlays'
  end

  class AISInstrument
    include Neo4j::ActiveNode
    property :name
    has_many :in, :members, model_class: 'AISMember', rel_class: 'AISPlays'
  end

  class AISHasMember
    include Neo4j::ActiveRel
    from_class AISBand
    to_class AISMember
  end

  class AISPlays
    include Neo4j::ActiveRel
    from_class AISMember
    to_class AISInstrument
  end

  let!(:tool)     { AISBand.create(name: 'Tool') }
  let!(:maynard)  { AISMember.create(name: 'Maynard') }
  let!(:adam)     { AISMember.create(name: 'Adam') }
  let!(:danny)    { AISMember.create(name: 'Danny') }
  let!(:vocals)   { AISInstrument.create(name: 'Vocals') }
  let!(:guitar)   { AISInstrument.create(name: 'Guitar') }
  let!(:drums)    { AISInstrument.create(name: 'Drums') }

  before do
    tool.members << [maynard, adam, danny]
    maynard.instruments << vocals
    adam.instruments << guitar
    danny.instruments << drums
  end

  after { [AISBand, AISMember, AISInstrument].each(&:delete_all) }

  describe 'preloading association by name' do
    context '.includes' do
      it 'preloads the association cache' do
        band = AISBand.where(name: 'Tool').includes(:members).to_a.first
        expect(band.association_cache[:members]).not_to be_empty
        expect(band.association_cache[:members].values.first).to include(maynard, adam, danny)
      end
    end
  end

  # This is the only difference between `includes` and `includes_filtered`
  describe 'filtering included association' do
    context 'includes' do
      it 'cannot filter matches' do
        expect { AISBand.where(name: 'Tool').includes(:members).where(name: 'Maynard') }.to raise_error NoMethodError
      end
    end

    context '.includes with block for filtering' do
      it 'can filter the match' do
        band = AISBand.where(name: 'Tool').includes(:members) { |members| members.where(name: 'Maynard') }.to_a.first
        expect(band.association_cache[:members].values.first.count).to eq 1
        expect(band.association_cache[:members].values.first.first).to eq(maynard)
      end

      it 'explodes when trying to include within the block' do
        expect { AISBand.all.includes(:members) { |members| members.includes(:instruments) } }.to raise_error
      end
    end
  end

  it 'accepts an id representing the child node' do
    q = AISBand.as(:a).where(name: 'Tool').includes(:members, :b)
    expect(q.to_cypher).to include 'OPTIONAL MATCH (a:`AISBand`), (b:`AISMember`)'
  end

  it 'accepts a symbol for the rel between the parent and child' do
    q = AISBand.as(:a).where(name: 'Tool').includes(:members, nil, :included_foo_rel)
    expect(q.to_cypher).to include '-[included_foo_rel:`AIS_HAS_MEMBER`]->'
  end

  it 'preloades on instances' do
    members = tool.members.includes(:instruments).to_a
    expect(tool.association_cache).not_to be_empty
    expect(members.first.association_cache[:instruments]).not_to be_empty
    members.each do |member|
      case member
      when maynard
        expect(member.association_cache[:instruments].values.first).to include vocals
      when adam
        expect(member.association_cache[:instruments].values.first).to include guitar
      when danny
        expect(member.association_cache[:instruments].values.first).to include drums
      else
        fail 'unexpected results'
      end
    end
  end

  it 'does not break the association cache of the calling node' do
    members = tool.members.includes(:instruments).to_a
    expect(tool.association_cache[:members].first.last.first).to be_a(AISMember)
  end

  describe 'first' do
    it 'returns the first match and populates its association cache' do
      result = tool.members.where(name: 'Maynard').includes(:instruments).first
      expect(result).to eq maynard
      # This might seem odd but I'm tired and it's a way to get to the contents of the association cache.
      # TODO: Fix it. In the meantime...
      # association_cache = { instruments: { long_cypher_integer: [preloaded_nodes] }}]
      # In this case, the preloaded node == vocals
      expect(result.association_cache[:instruments].first.last.first).to eq vocals
    end
  end

  describe 'each_with_rel' do
    it 'preloads rels' do
      tool.members.where(name: 'Maynard').includes(:instruments).each_with_rel do |member, rel|
        expect(member).to be_a(AISMember)
        expect(rel).to be_a(AISHasMember)
        expect(member.association_cache[:instruments].count).to eq 1
        member.instruments.each_with_rel do |instrument, instrument_rel|
          expect(instrument).to be_a(AISInstrument)
          expect(instrument_rel).to be_a(AISPlays)
        end
        expect(member.association_cache[:instruments].count).to eq 1
      end
    end
  end
end
