describe ActiveGraph::Migrations::Helpers do
  include described_class
  include ActiveGraph::Migrations::Helpers::Schema
  include ActiveGraph::Migrations::Helpers::IdProperty
  include ActiveGraph::Migrations::Helpers::Relationships

  before do
    clear_model_memory_caches

    stub_node_class('Bookcase') do
      has_many :out, :books, type: :has_books
    end

    create_constraint(:Book, :name, type: :unique)
    create_index(:Book, :author_name, type: :exact)
    stub_node_class('Book') do
      property :name
      property :author_name
    end

    Book.create!(name: 'Book1')
    Book.create!(name: 'Book2')
    Book.create!(name: 'Book3')
  end

  describe '#remove_property' do
    it 'removes a property' do
      remove_property :Book, :name
      expect(Book.all(:n).pluck('n.name')).to eq([nil, nil, nil])
    end
  end

  describe '#rename_property' do
    it 'renames a property' do
      rename_property :Book, :name, :title
      expect(Book.all(:n).pluck('n.title')).to include('Book1', 'Book2', 'Book3')
    end

    it 'fails to remove when destination property is already defined' do
      expect { rename_property :Book, :author_name, :name }.to raise_error(
        'Property `name` is already defined in `Book`. To overwrite, call `remove_property(:Book, :name)` before this method.')
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
      add_labels :Book, [:Item, :Readable]
      expect(Book.first.labels).to match_array([:Book, :Item, :Readable])
    end
  end

  describe '#remove_labels' do
    it 'removes labels from a node' do
      add_label :Book, :Item
      expect(Book.first.labels).to match_array([:Book, :Item])
      remove_label :Book, :Item
      expect(Book.first.labels).to eq([:Book])
    end
  end

  describe '#rename_label' do
    it 'renames a label' do
      execute 'CREATE (n:`Item` { name: "Lorem Ipsum" })'
      rename_label :Item, :Book
      expect(Book.find_by(name: 'Lorem Ipsum')).not_to be_nil
    end
  end

  describe '#execute' do
    it 'executes plan cypher query with parameters' do
      expect do
        execute 'MATCH (b:`Book`) WHERE b.name = $book_name DELETE b', book_name: Book.first.name
      end.to change { Book.count }.by(-1)
    end
  end

  describe '#say' do
    it 'prints some text' do
      expect(self).to receive(:output).with('-- Hello')
      say 'Hello'
    end

    it 'prints some text as sub item' do
      expect(self).to receive(:output).with('   -> Hello')
      say 'Hello', :subitem
    end
  end

  describe '#say_with_time' do
    it 'wraps a block within some text' do
      text = ''
      allow(self).to receive(:output) do |new_text|
        text += "#{new_text}\n"
      end
      say_with_time 'Hello' do
        sleep 0.1
        12
      end
      expect(text).to match(/-- Hello\n   -> [0-9]\.[0-9]+s\n   -> 12 rows\n/)
    end
  end

  def label_object
    ActiveGraph::Core::Label.new(:Book)
  end

  describe '#add_constraint' do
    after { drop_constraint :Book, :code if label_object.constraint?(:code) }

    it 'adds a constraint to a property' do
      expect do
        add_constraint :Book, :code
      end.to change { label_object.constraint?(:code) }.from(false).to(true)
    end

    it 'fails when constraint is already defined' do
      expect do
        expect { add_constraint :Book, :name }.to raise_error('Duplicate constraint for Book#name')
      end.not_to change { label_object.constraint?(:name) }
    end

    it 'does not fail when constraint is already defined when forced' do
      add_constraint :Book, :genre
      expect do
        expect { add_constraint :Book, :genre, force: true }.not_to raise_error
      end.not_to change { label_object.constraint?(:genre) }
    end
  end

  describe '#add_index' do
    after { drop_index :Book, :pages if label_object.index?(:pages) }
    it 'adds an index to a property' do
      expect do
        add_index :Book, :pages
      end.to change { label_object.index?(:pages) }.from(false).to(true)
    end

    it 'fails when index is already defined' do
      expect do
        expect { add_index :Book, :author_name }.to raise_error('Duplicate index for Book#author_name')
      end.not_to change { label_object.indexes.flatten.count }
    end

    it 'does not fail when index is already defined when forced' do
      add_index :Book, :isbn
      expect do
        expect { add_index :Book, :isbn, force: true }.not_to raise_error
      end.not_to change { label_object.index?(:isbn) }
    end
  end

  describe '#populate_id_property' do
    before do
      3.times do
        execute 'CREATE (c:`Cat`)'
        execute 'CREATE (d:`Dog`)'
      end

      stub_node_class('Cat') {}
      stub_node_class('Dog') do
        id_property :my_id, on: :generate_id

        def generate_id
          "id-#{rand}"
        end
      end
    end

    it 'populates uuid' do
      populate_id_property :Cat
      uuids = Cat.all.pluck(:uuid)
      expect(uuids.count).to eq(3)
      expect(uuids.all? { |u| u =~ /\A([a-z0-9]+\-?)+\Z/ }).to be_truthy
    end

    it 'populates custom ids' do
      populate_id_property :Dog
      uuids = Dog.all(:n).pluck('n.my_id')
      expect(uuids.all? { |u| u.start_with?('id-') }).to be_truthy
    end
  end

  describe '#change_relations_style' do
    let(:migrate!) { change_relations_style(%w(has_books), :lower_hashtag, :lower) }

    before do
      Bookcase.create!
    end

    context 'when there\'s some data to migrate' do
      before do
        query.match('(bc:`Bookcase`)').match('(b:`Book`)').create('(bc)-[r:`#has_books`]->(b)').pluck(:r)
      end

      it 'converts the old format to the new' do
        expect { migrate! }.to change { Bookcase.first.books.size }.from(0).to(3)
      end

      it 'cleans up the old relationship' do
        expect { migrate! }.to change { query.match('()-[r:`#has_books`]->()').pluck(:r).size }.from(3).to(0)
      end
    end

    it 'keeps the relationship\'s properties' do
      query.match('(bc:`Bookcase`)').match('(b:`Book`)').create('(bc)-[r:`#has_books` { foo: "bar"}]->(b)').pluck(:r)

      old_rels = query.match('()-[r:`#has_books`]->()').pluck(:r)
      expect(old_rels.map { |e| e.properties[:foo] }).to eq(['bar'] * 3)
      migrate!
      new_rel = query.match('()-[r:`has_books`]->()').pluck(:r)
      expect(new_rel.map { |e| e.properties[:foo] }).to eq(['bar'] * 3)
    end

    it 'does not relabel relationships already in the requested format' do
      query.match('(bc:`Bookcase`)').match('(b:`Book`)').create('(bc)-[r:`has_books`]->(b)').pluck(:r)

      expect { migrate! }.not_to change { Bookcase.first.books.size }
    end

    it 'does not fail if no old-style relationships are found' do
      expect { migrate! }.not_to raise_error
    end
  end

  describe '#relabel_relation' do
    before do
      Bookcase.create!
      query.match('(bc:`Bookcase`)').match('(b:`Book`)').create('(bc)-[r:`something`]->(b)').pluck(:r)
    end

    it 'relabels a relation' do
      expect do
        relabel_relation :something, :something_else
      end.to change { query.match('()-[r]-()').pluck(:r).first.type }.from(:something).to(:something_else)
    end

    it 'relabels a relation giving :from, :to and :direction' do
      expect do
        relabel_relation :something, :something_else, from: :Book, to: :Bookcase, direction: :in
      end.to change { query.match('()-[r]-()').pluck(:r).first.type }.from(:something).to(:something_else)
    end

    it 'relabels nothing when giving wrong :from and :to' do
      expect do
        relabel_relation :something, :something_else, from: :Cat, to: :Dog
      end.not_to change { query.match('()-[r]-()').pluck(:r).first.type }.from(:something)
    end

    it 'runs relabeling in batches' do
      ENV['MAX_PER_BATCH'] = '2'
      expect(self).to receive(:output).exactly(2).times
      relabel_relation :something, :something_else
      ENV['MAX_PER_BATCH'] = nil
    end
  end

  describe '#drop_constraint' do
    it 'removes a constraint from a property' do
      expect do
        drop_constraint :Book, :name
      end.to change { label_object.constraint?(:name) }.from(true).to(false)
      expect { Book.create! name: Book.first.name }.not_to raise_error
    end

    it 'fails when constraint is not defined' do
      expect { drop_constraint :Book, :missing }.to raise_error('No such constraint for Book#missing')
    end
  end

  describe '#drop_index' do
    it 'removes an index from a property' do
      expect do
        drop_index :Book, :author_name
      end.to change { label_object.index?(:author_name) }.from(true).to(false)
    end

    it 'fails when index is not defined' do
      expect do
        expect { drop_index :Book, :missing }.to raise_error('No such index for Book#missing')
      end.not_to change { label_object.indexes.flatten.count }
    end
  end
end
