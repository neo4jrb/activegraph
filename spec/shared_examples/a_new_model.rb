shared_examples 'a new model' do

  context 'when created with #new()' do
    let(:new_instance) do
      clazz.new
    end

    it 'does not have any attributes' do
      new_instance.attributes.should == {}
    end

    it 'returns nil when asking for a attribute' do
      new_instance['name'].should be_nil
    end

    it 'can set attributes' do
      new_instance['name'] = 'foo'
      new_instance['name'].should == 'foo'
    end

    it 'allows symbols instead of strings in [] and []= operator' do
      new_instance[:name] = 'foo'
      new_instance['name'].should == 'foo'
      new_instance[:name].should == 'foo'
    end

    it 'allows setting attribtue to nil' do
      new_instance['name'] = nil
      new_instance['name'].should be_nil
      new_instance['name'] = 'foo'
      new_instance['name'] = nil
      new_instance['name'].should be_nil
    end
  end

end