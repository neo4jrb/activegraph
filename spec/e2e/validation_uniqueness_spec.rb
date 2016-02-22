describe Neo4j::ActiveNode::Validations do
  before(:each) do
    delete_db
    clear_model_memory_caches

    stub_active_node_class('Foo') do
      property :name

      validates_uniqueness_of :name
    end
  end

  context 'validating uniqueness of' do
    it 'should not fail if object is new' do
      o = Foo.new
      expect(o).not_to have_error_on(:name)
    end

    it 'should not fail when new object is out of scope' do
      other_clazz = UniqueClass.create do
        include Neo4j::ActiveNode
        property :name
        property :adult
        validates_uniqueness_of :name, scope: :adult
      end
      o = other_clazz.new('name' => 'joe', :adult => true)
      expect(o.save).to be true

      o2 = other_clazz.new('name' => 'joe', :adult => false)
      expect(o2).to be_valid
    end

    it 'should work with i18n taken message' do
      Foo.create(name: 'joe')
      o = Foo.create(name: 'joe')
      expect(o).to have_error_on(:name, 'has already been taken')
    end

    it 'should allow to update an object' do
      o = Foo.new('name' => 'joe')
      expect(o.save).to be true
      o.name = 'joe'
      expect(o.valid?).to be true
      expect(o).not_to have_error_on(:name)
    end

    it 'should fail if object name is not unique' do
      o = Foo.new('name' => 'joe')
      expect(o.save).to be true

      allow(Foo) \
        .to receive(:first) \
        .with(name: 'joe') \
        .and_return(o)

      o2 = Foo.new('name' => 'joe')
      expect(o2).to have_error_on(:name)
    end

    it 'should allow multiple blank entries if :allow_blank => true' do
      other_clazz = UniqueClass.create do
        include Neo4j::ActiveNode
        property :name
        validates_uniqueness_of :name, allow_blank: :true
      end

      o = other_clazz.new('name' => '')
      expect(o.save).to be true

      allow(other_clazz) \
        .to receive(:first) \
        .with(name: '') \
        .and_return(o)

      o2 = other_clazz.new('name' => '')
      expect(o2).not_to have_error_on(:name)
    end

    it 'should allow multiple nil entries if :allow_nil => true' do
      other_clazz = UniqueClass.create do
        include Neo4j::ActiveNode
        property :name
        validates_uniqueness_of :name, allow_nil: :true
      end

      o = other_clazz.new('name' => nil)
      expect(o.save).to be true

      o2 = other_clazz.new('name' => nil)
      expect(o2).not_to have_error_on(:name)
    end

    it 'should allow entries that differ only in case by default' do
      other_clazz = UniqueClass.create do
        include Neo4j::ActiveNode
        property :name
        validates_uniqueness_of :name
      end

      o = other_clazz.new('name' => 'BLAMMO')
      expect(o.save).to be true

      o2 = other_clazz.new('name' => 'blammo')
      expect(o2).not_to have_error_on(:name)
    end

    context 'with :case_sensitive => false' do
      before do
        stub_active_node_class('Foo') do
          property :name
          validates_uniqueness_of :name, case_sensitive: false
        end
      end

      it 'should fail on entries that differ only in case' do
        o = Foo.new('name' => 'BLAMMO')
        expect(o.save).to be true

        o2 = Foo.new('name' => 'blammo')
        expect(o2).to have_error_on(:name)
      end

      it 'should not raise an error if value is nil' do
        o = Foo.new('name' => nil)
        expect { o.valid? }.not_to raise_error
      end

      it 'should not raise an error if special Regexp characters used' do
        o = Foo.new('name' => '?')
        expect { o.valid? }.not_to raise_error
      end

      it 'should not always match if Regexp wildcard used' do
        o = Foo.new('name' => 'John')
        expect(o.save).to be true

        o2 = Foo.new('name' => '.*')
        expect(o2.valid?).to be true
      end

      it 'should check for uniqueness using entire string' do
        o = Foo.new('name' => 'John Doe')
        expect(o.save).to be true

        o2 = Foo.new('name' => 'John')
        expect(o2.valid?).to be true
      end
    end

    context 'scoped by a single attribute' do
      before do
        stub_active_node_class('Foo') do
          property :name
          property :scope
          validates_uniqueness_of :name, scope: :scope
        end
      end

      it 'should fail if the same name exists in the scope' do
        o = Foo.new('name' => 'joe', 'scope' => 'one')
        expect(o.save).to be true

        allow(Foo) \
          .to receive(:first) \
          .with(name: 'joe', scope: 'one') \
          .and_return(o)

        o2 = Foo.new('name' => 'joe', 'scope' => 'one')
        expect(o2).to have_error_on(:name)
      end

      it 'should pass if the same name exists in a different scope' do
        o = Foo.new('name' => 'joe', 'scope' => 'one')
        expect(o.save).to be true

        allow(Foo) \
          .to receive(:first) \
          .with(name: 'joe', scope: 'two') \
          .and_return(nil)

        o2 = Foo.new('name' => 'joe', 'scope' => 'two')
        expect(o2).not_to have_error_on(:name)
      end
    end

    context 'scoped by a multiple attributes' do
      before do
        stub_active_node_class('Foo') do
          property :name
          property :first_scope
          property :second_scope
          validates_uniqueness_of :name, scope: [:first_scope, :second_scope]
        end
      end

      it 'should fail if the same name exists in the scope' do
        o = Foo.new('name' => 'joe', 'first_scope' => 'one', 'second_scope' => 'two')
        expect(o.save).to be true

        allow(Foo) \
          .to receive(:first) \
          .with(name: 'joe', first_scope: 'one', second_scope: 'two') \
          .and_return(o)

        o2 = Foo.new('name' => 'joe', 'first_scope' => 'one', 'second_scope' => 'two')
        expect(o2).to have_error_on(:name)
      end

      it 'should pass if the same name exists in a different scope' do
        o = Foo.new('name' => 'joe', 'first_scope' => 'one', 'second_scope' => 'two')
        expect(o.save).to be true

        allow(Foo) \
          .to receive(:first) \
          .with(name: 'joe', first_scope: 'one', second_scope: 'one') \
          .and_return(nil)

        o2 = Foo.new('name' => 'joe', 'first_scope' => 'one', 'second_scope' => 'one')
        expect(o2).not_to have_error_on(:name)
      end
    end
  end
end
