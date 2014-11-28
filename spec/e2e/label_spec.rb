require 'spec_helper'


describe "Neo4j::ActiveNode" do
  let(:clazz) do
    UniqueClass.create do
      include Neo4j::ActiveNode
    end
  end

  let(:label_name) do
    clazz.to_s.to_sym
  end

  describe "labels" do
    context 'with _persisted_obj.labels present' do
      it "returns the label of the class" do
        expect(clazz.create.labels).to eq([label_name])
      end
    end
  end

  describe 'property' do

    describe 'property :age, index: :exact' do
      let(:clazz) do
        UniqueClass.create do
          include Neo4j::ActiveNode
        end
      end

      it 'creates an index' do
        clazz.should_receive(:index).with(:age, {:index=>:exact})
        clazz.property :age, index: :exact
      end
    end

    describe 'property :name, constraint: :unique' do
      it 'delegates to the Neo4j::Label class' do
        clazz = UniqueClass.create { include Neo4j::ActiveNode}
        expect_any_instance_of(Neo4j::Label).to receive(:create_constraint).with(:name, {type: :unique}, Neo4j::Session.current)
        clazz.property :name, constraint: :unique
      end
    end


    describe 'property :age, index: :exact, constraint: :unique' do
      let(:clazz) do
        UniqueClass.create do
          include Neo4j::ActiveNode
        end
      end

      it 'creates a constraint but not an index' do # creating an constraint does also automatically create an index
        expect(clazz).to_not receive(:index)
        expect_any_instance_of(Neo4j::Label).to receive(:create_constraint).with(:age, {type: :unique}, Neo4j::Session.current)
        clazz.property :age, index: :exact, constraint: :unique
      end
    end

    describe 'property :age, constraint: :unique' do
      let(:clazz) do
        UniqueClass.create do
          include Neo4j::ActiveNode
        end
      end

      it 'creates a constraint but not an index' do # creating an constraint does also automatically create an index
        clazz.should_not_receive(:index).with(:age, {:index=>:exact})
        clazz.should_receive(:constraint).with(:age, {type: :unique})
        clazz.property :age, constraint: :unique
      end
    end

  end


  describe 'constraint' do
    let(:clazz_with_constraint) do
      UniqueClass.create do
        include Neo4j::ActiveNode
        property :name
        constraint :name, type: :unique

        property :colour
        index :colour, constraint: {type: :unique}
      end
    end

    describe 'constraint :name, type: :unique' do
      it 'can not create two nodes with unique properties' do
        clazz_with_constraint.create(name: 'foobar')
        expect{clazz_with_constraint.create(name: 'foobar')}.to raise_error
      end

      it 'can create two nodes with different properties' do
        clazz_with_constraint.create(name: 'foobar1')
        expect{clazz_with_constraint.create(name: 'foobar2')}.to_not raise_error
      end

    end

    describe 'index :colour, constraint: {type: :unique}' do
      it 'can not create two nodes with unique properties' do
        clazz_with_constraint.create(colour: 'red')
        expect{clazz_with_constraint.create(colour: 'red')}.to raise_error
      end
    end

  end

  describe 'index' do

    let(:clazz) do
      UniqueClass.create do
        include Neo4j::ActiveNode
        property :name
        index :name
      end
    end

    let(:other_class) do
      UniqueClass.create do
        include Neo4j::ActiveNode
      end
    end

    it 'creates an index' do
      expect(clazz.mapped_label.indexes).to eq(:property_keys => [[:name], [:uuid]])
    end

    it 'does not create index on other classes' do
      expect(clazz.mapped_label.indexes).to eq(:property_keys => [[:name], [:uuid]])
      expect(other_class.mapped_label.indexes).to eq(:property_keys => [[:uuid]])
    end

    describe 'when inherited' do
      it 'has an index on both base and subclass' do
        class Foo1
          include Neo4j::ActiveNode
          property :name, index: :exact
        end
        class Foo2 < Foo1

        end
        expect(Foo1.mapped_label.indexes).to eq(:property_keys => [[:name], [:uuid]])
        expect(Foo2.mapped_label.indexes).to eq(:property_keys => [[:name], [:uuid]])
      end

    end
  end

  describe 'index?' do
    let(:clazz) do
      UniqueClass.create do
        include Neo4j::ActiveNode
        property :name
        index :name
      end
    end

    it 'indicates whether a property is indexed' do
      expect(clazz.index?(:name)).to be_truthy
      expect(clazz.index?(:foo)).to be_falsey
    end
  end

  describe 'add_label' do
    it "can add one label" do
      node = clazz.create
      node.add_label(:foo)
      expect(node.labels).to match_array([label_name, :foo])
    end

    it "can add two label" do
      node = clazz.create
      node.add_label(:foo, :bar)
      expect(node.labels).to match_array([label_name, :foo, :bar])
    end

  end


  describe 'remove_label' do
    it "can remove one label" do
      node = clazz.create
      node.add_label(:foo)
      node.remove_label(:foo)
      expect(node.labels).to match_array([label_name])
    end

    it "can add two label" do
      node = clazz.create
      node.add_label(:foo, :bar, :baaz)
      node.remove_label(:foo, :baaz)
      expect(node.labels).to match_array([label_name, :bar])
    end

  end

  describe 'setting association values via initialize' do
    let(:clazz) do
      UniqueClass.create do
        include Neo4j::ActiveNode
        property :name
        has_one :out, :foo
      end
    end

    it 'indicates whether a property is indexed' do
      stub_const('::Foo', Class.new { include Neo4j::ActiveNode })

      o = clazz.new(name: 'Jim', foo: 2)

      o.name.should == 'Jim'
      o.foo.should be_nil

      o.save!

      o.name.should == 'Jim'
      o.foo.should be_nil
    end
  end

  describe '.find' do
    let(:clazz) do
      UniqueClass.create do
        include Neo4j::ActiveNode
      end
    end

    let(:object1) { clazz.create }
    let(:object2) { clazz.create }

    describe 'finding individual records' do
      it 'by id' do
        clazz.find(object1.id).should == object1
      end

      it 'by object' do
        clazz.find(object1).should == object1
      end
    end

    describe 'finding multiple records' do
      it 'by id' do
        clazz.find([object1.id, object2.id]).to_set.should == [object1, object2].to_set
      end

      it 'by object' do
        clazz.find([object1, object2]).to_set.should == [object1, object2].to_set
      end
    end
  end
end
