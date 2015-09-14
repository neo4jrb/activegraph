require 'spec_helper'

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
      o.should_not have_error_on(:name)
    end

    it 'should not fail when new object is out of scope' do
      other_clazz = UniqueClass.create do
        include Neo4j::ActiveNode
        property :name
        property :adult
        validates_uniqueness_of :name, scope: :adult
      end
      o = other_clazz.new('name' => 'joe', :adult => true)
      o.save.should be true

      o2 = other_clazz.new('name' => 'joe', :adult => false)
      o2.should be_valid
    end

    it 'should work with i18n taken message' do
      Foo.create(name: 'joe')
      o = Foo.create(name: 'joe')
      o.should have_error_on(:name, 'has already been taken')
    end

    it 'should allow to update an object' do
      o = Foo.new('name' => 'joe')
      o.save.should be true
      o.name = 'joe'
      o.valid?.should be true
      o.should_not have_error_on(:name)
    end

    it 'should fail if object name is not unique' do
      o = Foo.new('name' => 'joe')
      o.save.should be true

      Foo \
        .stub(:first) \
        .with(name: 'joe') \
        .and_return(o)

      o2 = Foo.new('name' => 'joe')
      o2.should have_error_on(:name)
    end

    it 'should allow multiple blank entries if :allow_blank => true' do
      other_clazz = UniqueClass.create do
        include Neo4j::ActiveNode
        property :name
        validates_uniqueness_of :name, allow_blank: :true
      end

      o = other_clazz.new('name' => '')
      o.save.should be true

      other_clazz \
        .stub(:first) \
        .with(name: '') \
        .and_return(o)

      o2 = other_clazz.new('name' => '')
      o2.should_not have_error_on(:name)
    end

    it 'should allow multiple nil entries if :allow_nil => true' do
      other_clazz = UniqueClass.create do
        include Neo4j::ActiveNode
        property :name
        validates_uniqueness_of :name, allow_nil: :true
      end

      o = other_clazz.new('name' => nil)
      o.save.should be true

      o2 = other_clazz.new('name' => nil)
      o2.should_not have_error_on(:name)
    end

    it 'should allow entries that differ only in case by default' do
      other_clazz = UniqueClass.create do
        include Neo4j::ActiveNode
        property :name
        validates_uniqueness_of :name
      end

      o = other_clazz.new('name' => 'BLAMMO')
      o.save.should be true

      o2 = other_clazz.new('name' => 'blammo')
      o2.should_not have_error_on(:name)
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
        o.save.should be true

        o2 = Foo.new('name' => 'blammo')
        o2.should have_error_on(:name)
      end

      it 'should not raise an error if value is nil' do
        o = Foo.new('name' => nil)
        lambda { o.valid? }.should_not raise_error
      end

      it 'should not raise an error if special Regexp characters used' do
        o = Foo.new('name' => '?')
        lambda { o.valid? }.should_not raise_error
      end

      it 'should not always match if Regexp wildcard used' do
        o = Foo.new('name' => 'John')
        o.save.should be true

        o2 = Foo.new('name' => '.*')
        o2.valid?.should be true
      end

      it 'should check for uniqueness using entire string' do
        o = Foo.new('name' => 'John Doe')
        o.save.should be true

        o2 = Foo.new('name' => 'John')
        o2.valid?.should be true
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
        o.save.should be true

        Foo \
          .stub(:first) \
          .with(name: 'joe', scope: 'one') \
          .and_return(o)

        o2 = Foo.new('name' => 'joe', 'scope' => 'one')
        o2.should have_error_on(:name)
      end

      it 'should pass if the same name exists in a different scope' do
        o = Foo.new('name' => 'joe', 'scope' => 'one')
        o.save.should be true

        Foo \
          .stub(:first) \
          .with(name: 'joe', scope: 'two') \
          .and_return(nil)

        o2 = Foo.new('name' => 'joe', 'scope' => 'two')
        o2.should_not have_error_on(:name)
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
        o.save.should be true

        Foo \
          .stub(:first) \
          .with(name: 'joe', first_scope: 'one', second_scope: 'two') \
          .and_return(o)

        o2 = Foo.new('name' => 'joe', 'first_scope' => 'one', 'second_scope' => 'two')
        o2.should have_error_on(:name)
      end

      it 'should pass if the same name exists in a different scope' do
        o = Foo.new('name' => 'joe', 'first_scope' => 'one', 'second_scope' => 'two')
        o.save.should be true

        Foo \
          .stub(:first) \
          .with(name: 'joe', first_scope: 'one', second_scope: 'one') \
          .and_return(nil)

        o2 = Foo.new('name' => 'joe', 'first_scope' => 'one', 'second_scope' => 'one')
        o2.should_not have_error_on(:name)
      end
    end
  end
end
