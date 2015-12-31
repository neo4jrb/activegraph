# rubocop:disable Metrics/ModuleLength
# Originally part of ActiveAttr, https://github.com/cgriego/active_attr
module Neo4j::Shared
  describe Attributes do
    subject(:model) { model_class.new }
    let(:last_name) { 'Poweski' }

    let :model_class do
      Class.new do
        include Attributes
        attribute :first_name
        attribute :last_name
        attribute :amount

        def self.name
          'Foo'
        end

        def amount
          super
        end

        def amount=(*)
          super
        end

        def last_name=(value)
          super(value.to_s.upcase)
        end

        def last_name
          super || 'Poweski'
        end

        def initialize(first_name = nil)
          super()
          write_attribute(:first_name, first_name)
        end
      end
    end

    let :attributeless do
      Class.new.tap do |attributeless|
        attributeless.class_eval do
          include Attributes

          def self.name
            'Foo'
          end
        end
      end
    end

    describe '.attribute' do
      context 'a dangerous attribute' do
        before { model_class.stub(:dangerous_attribute?).and_return(true) }

        it { expect { model_class.attribute(:address) }.to raise_error Neo4j::DangerousAttributeError }
      end

      context 'a harmless attribute' do
        it 'creates an attribute with no options' do
          model_class.attributes.values.should include(AttributeDefinition.new(:first_name))
        end

        it 'returns the attribute definition' do
          model_class.attribute(:address).should == AttributeDefinition.new(:address)
        end

        it 'defines an attribute reader that calls #attribute' do
          model.should_receive(:attribute).with('first_name')
          model.first_name
        end

        it 'defines an attribute reader that can be called via super' do
          model.should_receive(:attribute).with('amount')
          model.amount
        end

        it 'defines an attribute writer that calls #attribute=' do
          model.should_receive(:attribute=).with('first_name', 'Ben')
          model.first_name = 'Ben'
        end

        it 'defines an attribute writer that can be called via super' do
          model.should_receive(:attribute=).with('amount', 1)
          model.amount = 1
        end

        it 'defining an attribute twice does not give the class two attribute definitions' do
          Class.new do
            include Attributes
            attribute :name
            attribute :name
          end.attributes.size.should == 1
        end

        it 'redefining an attribute replaces the attribute definition' do
          klass = Class.new do
            include Attributes
            attribute :name, type: Symbol
            attribute :name, type: String
          end

          klass.attributes.size.should eq 1
          klass.attributes[:name].should == AttributeDefinition.new(:name, type: String)
        end
      end
    end

    describe '.attribute!' do
      it 'can create an attribute with no options' do
        attributeless.attribute! :first_name
        attributeless.attributes.values.should include AttributeDefinition.new(:first_name)
      end

      it 'returns the attribute definition' do
        attributeless.attribute!(:address).should == AttributeDefinition.new(:address)
      end

      it 'defines an attribute reader that calls #attribute' do
        attributeless.attribute! :first_name
        model = attributeless.new
        result = double
        model.should_receive(:attribute).with('first_name').and_return(result)
        model.first_name.should equal result
      end

      it 'defines an attribute writer that calls #attribute=' do
        attributeless.attribute! :first_name
        model = attributeless.new
        model.should_receive(:attribute=).with('first_name', 'Ben')
        model.first_name = 'Ben'
      end
    end

    describe '.attributes' do
      it { model_class.should respond_to(:attributes) }

      it 'can access AttributeDefinition with a Symbol' do
        model_class.attributes[:first_name].should == AttributeDefinition.new(:first_name)
      end

      it 'can access AttributeDefinition with a String' do
        model_class.attributes['first_name'].should == AttributeDefinition.new(:first_name)
      end

      context 'when no attributes exist' do
        it { attributeless.attributes.should be_empty }
      end
    end

    describe '.inspect' do
      it 'renders the class name' do
        model_class.inspect.should match(/^Foo\(.*\)$/)
      end

      it 'renders the attribute names in alphabetical order' do
        model_class.inspect.should match '(amount, first_name, last_name)'
      end

      it "doesn't format the inspection string for attributes if the model does not have any" do
        attributeless.inspect.should == 'Foo'
      end
    end

    describe '#==' do
      subject { model_class.new('Ben') }

      it 'returns true when all attributes are equal' do
        should == model_class.new('Ben')
      end

      it 'returns false when compared to another type' do
        should_not == Struct.new(:attributes).new('first_name' => 'Ben')
      end
    end

    describe '#attributes' do
      context 'when no attributes are defined' do
        it 'returns an empty Hash' do
          attributeless.new.attributes.should == {}
        end
      end

      context 'when an attribute is defined' do
        it 'returns the key value pairs' do
          model.first_name = 'Ben'
          model.attributes.should include('first_name' => 'Ben')
        end

        it 'returns a new Hash ' do
          model.attributes.merge!('first_name' => 'Bob')
          model.attributes.should_not include('first_name' => 'Bob')
        end

        it 'returns all attributes' do
          model.attributes.keys.should =~ %w(amount first_name last_name)
        end
      end

      context 'when a getter is overridden' do
        it 'uses the overridden implementation' do
          model.attributes.should include('last_name' => last_name)
        end
      end
    end

    describe '#inspect' do
      before { model.first_name = 'Ben' }

      it 'includes the class name and all attribute values in alphabetical order by attribute name' do
        model.inspect.should == %(#<Foo amount: nil, first_name: "Ben", last_name: "#{last_name}">)
      end

      it "doesn't format the inspection string for attributes if the model does not have any" do
        attributeless.new.inspect.should == %(#<Foo>)
      end

      context 'when a getter is overridden' do
        it 'uses the overridden implementation' do
          model.inspect.should include %(last_name: "#{last_name}")
        end
      end
    end

    [:[], :read_attribute].each do |method|
      describe "##{method}" do
        context 'when an attribute is not set' do
          it 'returns nil' do
            model.send(method, :first_name).should be_nil
          end
        end

        context 'when an attribute is set' do
          let(:first_name) { 'Bob' }

          before { model.write_attribute(:first_name, first_name) }

          it 'returns the attribute using a Symbol' do
            model.send(method, :first_name).should == first_name
          end

          it 'returns the attribute using a String' do
            model.send(method, 'first_name').should == first_name
          end
        end

        context 'when the getter is overridden' do
          it 'uses the overridden implementation' do
            model.send(method, :last_name).should == last_name
          end
        end

        it 'raises when getting an undefined attribute' do
          expect do
            model.send(method, :initials)
          end.to raise_error Neo4j::UnknownAttributeError, 'unknown attribute: initials'
        end
      end
    end

    [:[]=, :write_attribute].each do |method|
      describe "##{method}" do
        it 'raises ArgumentError with one argument' do
          expect { model.send(method, :first_name) }.to raise_error(ArgumentError)
        end

        it 'raises ArgumentError with no arguments' do
          expect { model.send(method) }.to raise_error(ArgumentError)
        end

        it 'sets an attribute using a Symbol and value' do
          expect { model.send(method, :first_name, 'Ben') }.to change { model.attributes['first_name'] }.from(nil).to('Ben')
        end

        it 'sets an attribute using a String and value' do
          expect { model.send(method, 'first_name', 'Ben') }.to change { model.attributes['first_name'] }.from(nil).to('Ben')
        end

        it 'is able to set an attribute to nil' do
          model.first_name = 'Ben'
          expect { model.send(method, :first_name, nil) }.to change { model.attributes['first_name'] }.from('Ben').to(nil)
        end

        it 'uses the overridden implementation when the setter is overridden' do
          model.send(method, :last_name, 'poweski').should == 'POWESKI'
        end

        it 'raises when setting an undefined attribute' do
          expect do
            model.send(method, :initials, 'BP')
          end.to raise_error Neo4j::UnknownAttributeError, 'unknown attribute: initials'
        end
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
