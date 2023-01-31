require 'active_graph/migrations/schema'

describe ActiveGraph::Migrations::Schema do
  subject do
    described_class.synchronize_schema_data(schema_data, remove_missing)
    described_class.fetch_schema_data
  end
  let(:schema_data) { { indexes: indexes, constraints: constraints } }
  let(:remove_missing) { false }
  let(:all_indexes) { [range_index, point_index, fulltext_index, text_index].compact.sort }
  let(:all_constraints) { [unique_constraint, not_null_rel_prop_constraint, not_null_node_prop_constraint, node_key_constraint].compact.sort }
  let(:indexes) { [] }
  let(:constraints) { [] }

  let(:range_index) { 'CREATE RANGE INDEX `range_index` FOR (n:`Person`) ON (n.`nickname`)' }
  let(:point_index) { "CREATE POINT INDEX `point_index` FOR (n:`Person`) ON (n.`location`) OPTIONS {indexConfig: {`spatial.cartesian-3d.max`: [1000000.0, 1000000.0, 1000000.0],`spatial.cartesian-3d.min`: [-1000000.0, -1000000.0, -1000000.0],`spatial.cartesian.max`: [1000000.0, 1000000.0],`spatial.cartesian.min`: [-1000000.0, -1000000.0],`spatial.wgs-84-3d.max`: [180.0, 90.0, 1000000.0],`spatial.wgs-84-3d.min`: [-180.0, -90.0, -1000000.0],`spatial.wgs-84.max`: [180.0, 90.0],`spatial.wgs-84.min`: [-180.0, -90.0]}, indexProvider: 'point-1.0'}" }
  let(:fulltext_index) { "CREATE FULLTEXT INDEX `fulltext_index` FOR (n:`Friend`) ON EACH [n.`name`] OPTIONS {indexConfig: {`fulltext.analyzer`: 'swedish',`fulltext.eventually_consistent`: false}, indexProvider: 'fulltext-1.0'}" }
  let(:text_index) { "CREATE TEXT INDEX `text_index` FOR ()-[r:`KNOWS`]-() ON (r.`city`) OPTIONS {indexConfig: {}, indexProvider: 'text-2.0'}" }

  let(:unique_constraint) { "CREATE CONSTRAINT `unique_constraint` FOR (n:`Person`) REQUIRE (n.`name`) IS UNIQUE OPTIONS {indexConfig: {}, indexProvider: 'range-1.0'}" }
  let(:not_null_rel_prop_constraint) { 'CREATE CONSTRAINT `not_null_rel_prop_constraint` FOR ()-[r:`LIKED`]-() REQUIRE (r.`when`) IS NOT NULL' }
  let(:not_null_node_prop_constraint) { 'CREATE CONSTRAINT `not_null_node_prop_constraint` FOR (n:`Person`) REQUIRE (n.`name`) IS NOT NULL' }
  let(:node_key_constraint) { "CREATE CONSTRAINT `node_key_constraint` FOR (n:`Person`) REQUIRE (n.`name`, n.`surname`) IS NODE KEY OPTIONS {indexConfig: {}, indexProvider: 'range-1.0'}" }

  if ActiveGraph::Base.version?('<5')
    let(:text_index) { "CREATE TEXT INDEX `text_index` FOR ()-[r:`KNOWS`]-() ON (r.`city`)" }
  end

  if ActiveGraph::Base.version?('<4.4')
    let(:range_index) { "CREATE INDEX `range_index` FOR (n:`Person`) ON (n.`nickname`) OPTIONS {indexConfig: {`spatial.cartesian-3d.max`: [1000000.0, 1000000.0, 1000000.0],`spatial.cartesian-3d.min`: [-1000000.0, -1000000.0, -1000000.0],`spatial.cartesian.max`: [1000000.0, 1000000.0],`spatial.cartesian.min`: [-1000000.0, -1000000.0],`spatial.wgs-84-3d.max`: [180.0, 90.0, 1000000.0],`spatial.wgs-84-3d.min`: [-180.0, -90.0, -1000000.0],`spatial.wgs-84.max`: [180.0, 90.0],`spatial.wgs-84.min`: [-180.0, -90.0]}, indexProvider: 'native-btree-1.0'}" }
    let(:point_index) {}
    let(:text_index) {}

    let(:unique_constraint) { "CREATE CONSTRAINT `unique_constraint` ON (n:`Person`) ASSERT (n.`name`) IS UNIQUE OPTIONS {indexConfig: {`spatial.cartesian-3d.max`: [1000000.0, 1000000.0, 1000000.0],`spatial.cartesian-3d.min`: [-1000000.0, -1000000.0, -1000000.0],`spatial.cartesian.max`: [1000000.0, 1000000.0],`spatial.cartesian.min`: [-1000000.0, -1000000.0],`spatial.wgs-84-3d.max`: [180.0, 90.0, 1000000.0],`spatial.wgs-84-3d.min`: [-180.0, -90.0, -1000000.0],`spatial.wgs-84.max`: [180.0, 90.0],`spatial.wgs-84.min`: [-180.0, -90.0]}, indexProvider: 'native-btree-1.0'}" }
    let(:not_null_rel_prop_constraint) { 'CREATE CONSTRAINT `not_null_rel_prop_constraint` ON ()-[r:`LIKED`]-() ASSERT (r.`when`) IS NOT NULL' }
    let(:not_null_node_prop_constraint) { 'CREATE CONSTRAINT `not_null_node_prop_constraint` ON (n:`Person`) ASSERT (n.`name`) IS NOT NULL' }
    let(:node_key_constraint) { "CREATE CONSTRAINT `node_key_constraint` ON (n:`Person`) ASSERT (n.`name`, n.`surname`) IS NODE KEY OPTIONS {indexConfig: {`spatial.cartesian-3d.max`: [1000000.0, 1000000.0, 1000000.0],`spatial.cartesian-3d.min`: [-1000000.0, -1000000.0, -1000000.0],`spatial.cartesian.max`: [1000000.0, 1000000.0],`spatial.cartesian.min`: [-1000000.0, -1000000.0],`spatial.wgs-84-3d.max`: [180.0, 90.0, 1000000.0],`spatial.wgs-84-3d.min`: [-180.0, -90.0, -1000000.0],`spatial.wgs-84.max`: [180.0, 90.0],`spatial.wgs-84.min`: [-180.0, -90.0]}, indexProvider: 'native-btree-1.0'}" }
  end

  if ActiveGraph::Base.version?('<4.3')
    let(:range_index) { "INDEX FOR (n:Person) ON (n.nickname)" }
    let(:fulltext_index) {}

    let(:unique_constraint) { "CONSTRAINT ON (n:Person) ASSERT (n.name) IS UNIQUE" }
    let(:not_null_rel_prop_constraint) {}
    let(:not_null_node_prop_constraint) {}
    let(:node_key_constraint) {}
  end

  context 'empty' do
    it { is_expected.to eq schema_data }
  end

  context 'empty with removal' do
    let(:remove_missing) { true }
    it { is_expected.to eq schema_data }
  end

  context 'range index' do
    let(:indexes) { [range_index].compact }
    it { is_expected.to eq schema_data }
  end

  context 'point_index' do
    let(:indexes) { [point_index].compact }
    it { is_expected.to eq schema_data }
  end

  context 'fulltext_index' do
    let(:indexes) { [fulltext_index].compact }
    it { is_expected.to eq schema_data }
  end

  context 'text_index' do
    let(:indexes) { [text_index].compact }
    it { is_expected.to eq schema_data }
  end

  context 'unique_constraint' do
    let(:constraints) { [unique_constraint].compact }
    it { is_expected.to eq schema_data }
  end

  context 'not_null_rel_prop_constraint' do
    let(:constraints) { [not_null_rel_prop_constraint].compact }
    it { is_expected.to eq schema_data }
  end

  context 'not_null_node_prop_constraint' do
    let(:constraints) { [not_null_node_prop_constraint].compact }
    it { is_expected.to eq schema_data }
  end

  context 'node_key_constraint' do
    let(:constraints) { [node_key_constraint].compact }
    it { is_expected.to eq schema_data }
  end

  context 'indexes' do
    let(:indexes) { all_indexes }
    it { is_expected.to eq schema_data }
  end

  context 'constraint' do
    let(:constraints) { all_constraints }
    it { is_expected.to eq schema_data }
  end

  context 'drop missing' do
    before do
      described_class.synchronize_schema_data({ indexes: all_indexes, constraints: all_constraints }, false)
    end
    let(:indexes) { [range_index] }
    let(:constraints) { [unique_constraint] }
    let(:remove_missing) { true }
    it { is_expected.to eq schema_data }
  end
end
