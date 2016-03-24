# Originally part of ActiveAttr, https://github.com/cgriego/active_attr
shared_examples 'mass assignment class', mass_assignment: true do
  let :model_class do
    Class.new do
      attr_accessor :first_name, :last_name, :middle_name
      private :middle_name=

      def name=(name)
        self.last_name, self.first_name = name.split(nil, 2).reverse
      end
    end
  end

  let(:person) { model_class.new }
  let(:first_name) { 'Chris' }
  let(:last_name) { 'Griego' }

  def should_assign_names_to(person)
    expect(person.first_name).to eq first_name
    expect(person.last_name).to eq(last_name)
  end
end

shared_examples 'mass assignment method' do
  it 'does not raise when assigning nil attributes' do
    expect { mass_assign_attributes nil }.not_to raise_error
  end

  it 'assigns all valid attributes when passed as a hash with string keys' do
    should_assign_names_to mass_assign_attributes('first_name' => first_name, 'last_name' => last_name)
  end

  it 'assigns all valid attributes when passed as a hash with symbol keys' do
    should_assign_names_to mass_assign_attributes(first_name: first_name, last_name: last_name)
  end

  it 'uses any available writer methods' do
    should_assign_names_to mass_assign_attributes(name: "#{first_name} #{last_name}")
  end
end

shared_examples '#assign_attributes', assign_attributes: true do
  def mass_assign_attributes(attributes)
    person.assign_attributes attributes
    person
  end

  it 'raises ArgumentError when called with two arguments' do
    expect { model_class.new.assign_attributes({}, nil) }.to raise_error ArgumentError
  end

  it 'does not raise when called with a single argument' do
    expect { model_class.new.assign_attributes({}) }.not_to raise_error
  end

  it 'does not raise ArgumentError when called with no arguments' do
    expect { model_class.new.assign_attributes }.not_to raise_error
  end
end

shared_examples '#attributes=', :attributes= => true do
  def mass_assign_attributes(attributes)
    person.attributes = attributes
    person
  end

  it 'raises ArgumentError when called with two arguments' do
    expect { person.send(:attributes=, {}, {}) }.to raise_error ArgumentError
  end
end

shared_examples '#initialize', initialize: true do
  def mass_assign_attributes(attributes)
    model_class.new(attributes)
  end

  it 'raises ArgumentError when called with two arguments' do
    expect { model_class.new({}, {}) }.to raise_error ArgumentError
  end

  it 'does not raise when called with a single argument' do
    expect { model_class.new({}) }.not_to raise_error
  end

  it 'does not raise when called with no arguments' do
    expect { model_class.new }.not_to raise_error
  end
end
