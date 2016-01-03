module Neo4j::Shared
  describe TypecastedAttributes do
    subject(:model) { model_class.new }

    let :model_class do
      Class.new do
        include Property
        include Attributes
        include TypecastedAttributes

        property :amount, type: String
        property :first_name
        property :last_name

        def last_name_before_type_cast
          super
        end

        def self.name
          'Foo'
        end
      end
    end

    let :attributeless do
      Class.new do
        include TypecastedAttributes

        def self.name
          'Foo'
        end
      end
    end

    describe '.attribute' do
      it 'defines an attribute pre-typecasting reader that calls #attribute_before_type_cast' do
        model.should_receive(:attribute_before_type_cast).with('first_name')
        model.first_name_before_type_cast
      end

      it 'defines an attribute reader that can be called via super' do
        model.should_receive(:attribute_before_type_cast).with('last_name')
        model.last_name_before_type_cast
      end
    end

    describe '.inspect' do
      it 'renders the class name' do
        model_class.inspect.should match(/^Foo\(.*\)$/)
      end

      it 'renders the attribute names and types in alphabetical order, using Object for undeclared types' do
        model_class.inspect.should match '(amount: String, first_name: Object, last_name: Object)'
      end

      it "doesn't format the inspection string for attributes if the model does not have any" do
        attributeless.inspect.should == 'Foo'
      end
    end

    describe '#attribute_before_type_cast' do
      it 'returns nil when the attribute has not been assigned yet' do
        model.attribute_before_type_cast(:amount).should be_nil
      end

      it 'returns the assigned attribute value, without typecasting, when given an attribute name as a Symbol' do
        value = :value
        model.amount = value
        model.attribute_before_type_cast(:amount).should equal value
      end

      it 'returns the assigned attribute value, without typecasting, when given an attribute name as a String' do
        value = :value
        model.amount = value
        model.attribute_before_type_cast('amount').should equal value
      end
    end
  end
end
