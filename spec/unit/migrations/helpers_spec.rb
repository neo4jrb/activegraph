describe Neo4j::Migrations::Helpers do
  include described_class

  before do
    clear_model_memory_caches
    delete_db

    stub_active_node_class('Book') do
      property :name, constraint: :unique
      property :author_name, index: :exact
    end

    Book.create!(name: 'Book1')
    Book.create!(name: 'Book2')
    Book.create!(name: 'Book3')
  end

  describe '#rename_property' do
    it 'renames a property' do
      rename_property :Book, :name, :title
      expect(Book.all.pluck(n: :title)).to include('Book1', 'Book2', 'Book3')
    end
  end

  describe '#drop_nodes' do
    it 'drops all nodes given a label' do
      drop_nodes :Book
      expect(Book.all.count).to eq(0)
    end
  end

  describe '#add_labels' do
    it 'adds labels to a node' do
      add_labels :Book, :Item, :Readable
      expect(Book.first.labels).to eq([:Book, :Item, :Readable])
    end
  end

  describe '#remove_labels' do
    it 'removes labels from a node' do
      add_labels :Book, :Item
      expect(Book.first.labels).to eq([:Book, :Item])
      remove_labels :Book, :Item
      expect(Book.first.labels).to eq([:Book])
    end
  end

  describe '#remove_constraint' do
    it 'removes a constraint from a property' do
      remove_constraint :Book, :name
      expect { Book.create! name: Book.first.name }.not_to raise_error
    end
  end

  describe '#execute' do
    it 'executes plan cypher query with parameters' do
      expect do
        execute 'MATCH (b:`Book`) WHERE b.name = {book_name} DELETE b', book_name: Book.first.name
      end.to change { Book.count }.by(-1)
    end
  end

  describe '#remove_index' do
    it 'removes an index from a property' do
      remove_index :Book, :author_name
    end
  end
end
