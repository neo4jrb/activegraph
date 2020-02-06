describe Neo4j::ModelSchema do
  before { delete_schema }

  before do
    create_index :User, :name, type: :exact

    stub_active_node_class('User') do
      property :username, constraint: :unique
      property :name, index: :exact
      enum role: [:none, :staff, :admin]
    end

    stub_active_node_class('Book') do
      id_property :isbn
    end
  end

  let(:schema) { described_class.legacy_model_schema_informations }

  it 'lists every legacy schema information' do
    Book.ensure_id_property_info!
    expect(schema[:constraint]).to match_array([
                                                 {label: :Book, model: Book, property_name: :isbn},
                                                 {label: :User, model: User, property_name: :uuid},
                                                 {label: :User, model: User, property_name: :username}
                                               ])

    expect(schema[:index]).to match_array([
                                            {label: :User, model: User, property_name: :name},
                                            {label: :User, model: User, property_name: :role}
                                          ])
  end
end
