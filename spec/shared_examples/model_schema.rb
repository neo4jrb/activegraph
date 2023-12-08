shared_examples 'logs id_property constraint option false warning' do |model|
  it('logs id_property constraint option false warning') do
    expect(@base_logger).to have_received(:warn).with(/WARNING: The constraint option for id_property is no longer supported \(Used on #{model}/)
  end
end

shared_examples 'does not log id_property constraint option false warning' do |model|
  it('does not log id_property constraint option false warning') do
    expect(@base_logger).not_to have_received(:warn).with(/WARNING: The constraint option for id_property is no longer supported \(Used on #{model}/)
  end
end

shared_examples 'logs schema option warning' do |index_or_constraint, model, property_name|
  it("logs a warning that the #{index_or_constraint} definition for #{model}.#{property_name} is no longer needed") do
    model.to_s.constantize.first

    expect(@base_logger).to have_received(:warn)
      .with(/WARNING: The #{index_or_constraint} option is no longer supported \(Defined on #{model} for #{property_name}/)
  end
end

shared_examples 'does not log schema option warning' do |index_or_constraint, model, property_name = nil|
  it("does not log a warning that the #{index_or_constraint} definition for #{model} is no longer needed") do
    model.to_s.constantize.first

    expect(@base_logger).not_to have_received(:warn).with(
      /WARNING: The #{index_or_constraint} option is no longer supported \(Defined on #{model}#{" for #{property_name}" if property_name}/)
  end
end

shared_examples 'does not raise schema error' do |model|
  it 'does not raise schema error' do
    expect { model.to_s.constantize.first }.to_not raise_error
  end
end

shared_examples 'raises schema error including' do |index_or_constraint, model, property_name|
  let(:label) { model.to_s.constantize.mapped_element_name }
  it "raises error including #{index_or_constraint} for #{model}.#{property_name}" do
    expect do
      model.to_s.constantize.first
    end.to raise_error(/Some schema elements were defined.*rake neo4j:generate_schema_migration\[#{index_or_constraint},#{label},#{property_name}\]/m)
  end
end

shared_examples 'raises schema error not including' do |index_or_constraint, model, property_name = ''|
  let(:label) { model.to_s.constantize.mapped_element_name }
  it "raises error not including #{index_or_constraint} for #{model}.#{property_name}" do
    begin
      model.to_s.constantize.first

      fail 'Expected an error to be raised'
    rescue Exception => e # rubocop:disable Lint/RescueException
      raise e unless e.message =~ /Some schema elements were defined/

      expect(e.message).to_not match(/force_add_#{index_or_constraint} #{label} #{property_name}/m)
    end
  end
end
