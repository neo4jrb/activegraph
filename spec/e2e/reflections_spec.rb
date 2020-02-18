describe 'reflections' do
  before do
    stub_active_node_class('MyClass') do
      has_many :in,  :in_things, model_class: self, type: 'things'
      has_many :out, :out_things, model_class: self, type: 'things'

      has_many :in, :in_things_string, model_class: self.to_s, type: 'things'
      has_many :out, :things_with_rel_class, model_class: self, rel_class: :RelClass
      has_many :out, :string_rel_class, model_class: self, rel_class: :RelClass
      has_one :out, :one_thing, model_class: self, type: 'one_thing'
    end

    stub_active_rel_class('RelClass') do
      from_class :any
      to_class :any
      type 'things'
    end
  end

  let(:clazz) { MyClass }
  let(:rel_clazz) { RelClass }

  it 'responds to :reflections' do
    expect { clazz.reflections }.not_to raise_error
  end

  it 'responds with a hash' do
    expect(clazz.reflections).to be_a(Hash)
  end

  it 'contains a key for each association' do
    expect(clazz.reflections).to have_key(:in_things)
    expect(clazz.reflections).to have_key(:out_things)
  end

  it 'returns information about a given association' do
    reflection = clazz.reflect_on_association(:in_things)
    expect(reflection).to be_a(ActiveGraph::ActiveNode::Reflection::AssociationReflection)
    expect(reflection.klass).to eq clazz
    expect(reflection.class_name).to eq clazz.name
    expect(reflection.type).to eq :things
    expect(reflection.collection?).to be_truthy
    expect(reflection.validate?).to be_truthy

    reflection = clazz.reflect_on_association(:one_thing)
    expect(reflection.collection?).to be_falsey
  end

  it 'returns a reflection for each association' do
    expect(clazz.reflect_on_all_associations.count).to eq 6
  end

  it 'recognizes rel classes' do
    reflection = clazz.reflect_on_association(:things_with_rel_class)
    expect(reflection.rel_klass).to eq rel_clazz
    expect(reflection.rel_class_name).to eq rel_clazz.name
  end
end
