describe ActiveGraph::Node::Validations do
  before(:each) do
    clear_model_memory_caches
  end

  context 'validating uniqueness of' do
    context 'with default' do
      before do
        stub_node_class('Foo') do
          property :name

          validates_uniqueness_of :name
        end
      end

      it 'should not fail if object is new' do
        o = Foo.new
        expect(o).not_to have_error_on(:name)
      end

      it 'should not fail when new object is out of scope' do
        stub_node_class('OtherClazz') do
          property :name
          property :adult
          validates_uniqueness_of :name, scope: :adult
        end
        o = OtherClazz.new('name' => 'joe', :adult => true)
        expect(o.save).to be true

        o2 = OtherClazz.new('name' => 'joe', :adult => false)
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

        o2 = Foo.new('name' => 'joe')
        expect(o2).to have_error_on(:name)
      end

      it 'should allow multiple blank entries if :allow_blank => true' do
        stub_node_class('OtherClazz') do
          property :name
          validates_uniqueness_of :name, allow_blank: :true
        end

        o = OtherClazz.new('name' => '')
        expect(o.save).to be true

        o2 = OtherClazz.new('name' => '')
        expect(o2).not_to have_error_on(:name)
      end

      it 'should allow multiple nil entries if :allow_nil => true' do
        stub_node_class('OtherClazz') do
          property :name
          validates_uniqueness_of :name, allow_nil: :true
        end

        o = OtherClazz.new('name' => nil)
        expect(o.save).to be true

        o2 = OtherClazz.new('name' => nil)
        expect(o2).not_to have_error_on(:name)
      end

      it 'should allow entries that differ only in case by default' do
        stub_node_class('OtherClazz') do
          property :name
          validates_uniqueness_of :name
        end

        o = OtherClazz.new('name' => 'BLAMMO')
        expect(o.save).to be true

        o2 = OtherClazz.new('name' => 'blammo')
        expect(o2).not_to have_error_on(:name)
      end
    end

    context 'with :case_sensitive => false' do
      before do
        stub_node_class('Foo') do
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
        stub_node_class('Foo') do
          property :name
          property :scope
          validates :name, uniqueness: { scope: :scope }
        end
      end

      it 'should fail if the same name exists in the scope' do
        o = Foo.new('name' => 'joe', 'scope' => 'one')
        expect(o.save).to be true

        o2 = Foo.new('name' => 'joe', 'scope' => 'one')
        expect(o2).to have_error_on(:name)
      end

      it 'should pass if the same name exists in a different scope' do
        o = Foo.new('name' => 'joe', 'scope' => 'one')
        expect(o.save).to be true

        o2 = Foo.new('name' => 'joe', 'scope' => 'two')
        expect(o2).not_to have_error_on(:name)
      end
    end

    context 'scoped by a multiple attributes' do
      before do
        stub_node_class('Foo') do
          property :name
          property :first_scope
          property :second_scope
          validates :name, uniqueness: { scope: [:first_scope, :second_scope] }
        end
      end

      it 'should fail if the same name exists in the scope' do
        o = Foo.new('name' => 'joe', 'first_scope' => 'one', 'second_scope' => 'two')
        expect(o.save).to be true

        o2 = Foo.new('name' => 'joe', 'first_scope' => 'one', 'second_scope' => 'two')
        expect(o2).to have_error_on(:name)
      end

      it 'should pass if the same name exists in a different scope' do
        o = Foo.new('name' => 'joe', 'first_scope' => 'one', 'second_scope' => 'two')
        expect(o.save).to be true

        o2 = Foo.new('name' => 'joe', 'first_scope' => 'one', 'second_scope' => 'one')
        expect(o2).not_to have_error_on(:name)
      end
    end

    context "scoped by a scope" do
      before do
        stub_node_class('Bar') do
          has_many :in, :foos, origin: :bar
        end
        stub_node_class('Foo') do
          property :name
          has_one :out, :bar, type: :bar
          validates :name, uniqueness: { scope: Proc.new { bar.foos } }
        end
      end
      let(:bar1) { Bar.create! }
      let(:bar2) { Bar.create! }

      it 'should fail if the same name exists in the scope' do
        o = Foo.new(name: 'joe', bar: bar1)
        expect(o.save).to be true

        o2 = Foo.new(name: 'joe', bar: bar1)
        expect(o2).to have_error_on(:name)
      end

      it 'should pass if the same name exists in a different scope' do
        o = Foo.new(name: 'joe', bar: bar1)
        expect(o.save).to be true

        o2 = Foo.new(name: 'joe', bar: bar2)
        expect(o2).not_to have_error_on(:name)
      end
    end
  end
end
