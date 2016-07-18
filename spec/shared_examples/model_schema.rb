shared_examples 'logs constraint option false warning' do |model|
  it('logs constraint option false warning') do
    expect(active_base_logger).to have_received(:warn).with(/WARNING: The constraint option is no longer supported \(Used on #{model}/)
  end
end

shared_examples 'does not log constraint option false warning' do |model|
  it('does not log constraint option false warning') do
    expect(active_base_logger).not_to have_received(:warn).with(/WARNING: The constraint option is no longer supported \(Used on #{model}/)
  end
end

shared_examples 'raises constraint error including' do |model, id_property_name|
  it 'raised error includes label / property' do
    expect { Clazz.first }.to raise_error /Some constraints were defined.*force_add_index #{model} #{id_property_name}/m
  end
end

shared_examples 'raises constraint error not including' do |model, id_property_name = ''|
  it 'raised error does not include label / property' do
    begin
      Clazz.first
    rescue Exception => e
      expect(e.message).to_not match(/Some constraints were defined.*force_add_index #{model} #{id_property_name}/m)
    end
  end
end

