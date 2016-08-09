shared_examples 'handles permitted parameters' do
  describe '#new' do
    it 'assigns permitted params' do
      using_action_controller do
        params.permit!
        expect(klass.new(create_params).attributes).to include(params.to_h)
      end
    end

    it 'fails on unpermitted parameters' do
      using_action_controller do
        expect { klass.new(create_params) }.to raise_error ActiveModel::ForbiddenAttributesError
      end
    end
  end

  describe '#create' do
    it 'assigns permitted params' do
      using_action_controller do
        params.permit!
        expect(klass.create(create_params).attributes).to include(params.to_h)
      end
    end

    it 'fails on unpermitted parameters' do
      using_action_controller do
        expect { klass.create(create_params) }.to raise_error ActiveModel::ForbiddenAttributesError
      end
    end
  end

  describe '#attributes=' do
    it 'assigns permitted params' do
      using_action_controller do
        params.permit!
        subject.attributes = params
        expect(subject.attributes).to include(params.to_h)
      end
    end

    it 'fails on unpermitted parameters' do
      using_action_controller do
        expect { subject.attributes = params }.to raise_error ActiveModel::ForbiddenAttributesError
      end
    end
  end

  describe '#update' do
    it 'assigns permitted params' do
      using_action_controller do
        params.permit!
        subject.update(params)
        expect(subject.attributes).to include(params.to_h)
      end
    end

    it 'fails on unpermitted parameters' do
      using_action_controller do
        expect { klass.new.update(params) }.to raise_error ActiveModel::ForbiddenAttributesError
      end
    end
  end
end
