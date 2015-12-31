module Neo4j::Shared
  describe MassAssignment, :mass_assignment do
    before do
      model_class.class_eval do
        include MassAssignment
      end
    end

    shared_examples 'lenient mass assignment method', lenient_mass_assignment_method: true do
      include_examples 'mass assignment method'

      it 'ignores attributes which do not have a writer' do
        person = mass_assign_attributes(middle_initial: 'J')
        person.instance_eval { @middle_initial ||= nil }
        person.instance_variable_get('@middle_initial').should be_nil
        person.should_not respond_to :middle_initial
      end

      it 'ignores trying to assign a private attribute' do
        person = mass_assign_attributes(middle_name: 'J')
        person.middle_name.should be_nil
      end
    end

    describe '#assign_attributes', :assign_attributes, :lenient_mass_assignment_method
    describe '#attributes=', :attributes=, :lenient_mass_assignment_method
    describe '#initialize', :initialize, :lenient_mass_assignment_method
  end
end
