require 'spec_helper'

# The `includes` method works by preloading a node's association cache with the results of a query.
# In these tests, we demonstrate that the association cache is prepopulated with the expected results.
# We do not test the association cache itself here because it has its own tests and we trust they are working properly.
describe 'association .includes method' do
  class AISBand
    include Neo4j::ActiveNode
    property :name
    has_many :out, :members, model_class: 'AISMember'
  end

  class AISMember
    include Neo4j::ActiveNode
    property :name
    has_many :in, :bands, model_class: 'AISBand', origin: :members
    has_many :out, :instruments, model_class: 'AISInstrument'
  end

  class AISInstrument
    include Neo4j::ActiveNode
    property :name
    has_many :in, :members, model_class: 'AISMember', origin: :instruments
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

  it 'preloads the association cache' do
    band = AISBand.where(name: 'Tool').includes(:members).to_a.first
    expect(band.association_cache[:members]).not_to be_empty
    expect(band.association_cache[:members].values.first).to include(maynard, adam, danny)
  end

  it 'can filter the match' do
    band = AISBand.where(name: 'Tool').includes(:members).where(name: 'Maynard').to_a.first
    expect(band.association_cache[:members].values.first.count).to eq 1
    expect(band.association_cache[:members].values.first.first).to eq(maynard)
  end

  it 'accepts a symbol for node_id'
  it 'accepts a symbol for child_id'
  it 'accepts a symbol for the rel between the node and child'

  it 'works on instances' do
    members = tool.members.includes(:instruments).to_a
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

  describe 'first' do
    it 'returns the first match and populates its association cache' do
      result = tool.members.where(name: 'Maynard').includes(:instruments).where(name: 'Vocals').first
      expect(result).to eq maynard
      # require 'pry'; binding.pry
      # This might seem odd but I'm tired and it's a way to get to the contents of the association cache.
      # TODO: Fix it. In the meantime...
      # association_cache = { instruments: { long_cypher_integer: [preloaded_node(s)] }}]
      # In this case, the preloaded node == vocals
      expect(result.association_cache[:instruments].first.last.first).to eq vocals
    end
  end
end
