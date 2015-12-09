describe 'works well together with Neo4j::Core' do
  let(:clazz) do
    UniqueClass.create do
      include Neo4j::ActiveNode
      has_many :out, :stuff, type: :stuff, model_class: false
    end
  end

  it 'can add Neo4j::Node to declared relationships' do
    obj = clazz.create
    node = Neo4j::Node.create
    obj.stuff << node
    result = Neo4j::Session.query.match(:n).where('ID(n) = {obj_neo_id}').params(obj_neo_id: obj.neo_id).match('(n)-[:stuff]->(m)')
    result = result.pluck(:m)
    expect(result).to eq([node])
  end

  it 'can retrieve Neo4j::Node from declared relationships' do
    obj = clazz.create
    node = Neo4j::Node.create
    obj.stuff << node
    expect(obj.stuff.to_a).to eq([node])
  end
end
