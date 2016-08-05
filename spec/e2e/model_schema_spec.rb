describe Neo4j::ModelSchema do
  before { delete_schema }

  before do
    create_constraint :User, :uuid, type: :unique
    create_index :User, :name, type: :exact

    stub_active_node_class('User') do
      property :username, constraint: :unique
      property :name, index: :exact
    end
  end

  let(:schema) { described_class.legacy_model_schema_informations }

  it 'lists every legacy schema information' do
    expect(schema[:constraint]).to contain_exactly(
      {label: :User, model: User, property_name: :uuid},
      label: :User, model: User, property_name: :username)

    expect(schema[:index]).to contain_exactly(label: :User, model: User, property_name: :name)
  end
end
