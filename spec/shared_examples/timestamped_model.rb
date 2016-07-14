shared_examples_for 'timestamped model' do
  context 'when saving' do
    context 'with explicitly changed created_at property' do
      it 'does not overwrite created_at property' do
        subject.created_at = Time.now.utc.round
        expect { subject.save! }.not_to change(subject, :created_at)
      end
    end
  end

  context 'when saved' do
    around do |example|
      Timecop.freeze do
        example.run
      end
    end

    before do
      @time = Time.now
      @tomorrow = Time.now.tomorrow
    end

    before { subject.save! }

    it 'should have set updated_at' do
      expect(subject.updated_at.to_i).to eq(@time.to_i)
    end

    it 'should have set created_at' do
      subject.created_at.to_i == @time.to_i
    end

    context 'when updated' do
      before { Timecop.freeze(@tomorrow) }

      it 'created_at is not changed' do
        expect { subject.update_attributes!(a: 1, b: 2) }.not_to change(subject, :created_at)
      end

      it 'should have altered the updated_at property' do
        expect { subject.update_attributes!(a: 1, b: 2) }.to change(subject, :updated_at)
      end

      describe '#touch' do
        it 'should change updated_at' do
          expect { subject.touch }.to change(subject, :updated_at)
        end

        it 'will not change created_at' do
          expect { subject.touch }.not_to change(subject, :created_at)
        end
      end

      context 'with missing updated_at' do
        before do
          Neo4j::Transaction.run { subject._persisted_obj.remove_property('updated_at') }
        end

        it 'creates the property' do
          expect { subject.reload }.to change { subject.updated_at }.from(instance_of(DateTime)).to(nil)
          expect { subject.touch }.to change { subject.updated_at }.from(nil)
        end
      end

      context 'with explicitly changed updated_at property' do
        before { subject.updated_at = Time.now }

        it 'does not overwrite updated_at property' do
          expect { subject.update_attributes!(a: 1, b: 2) }.not_to change(subject, :updated_at)
        end
      end

      context 'without modifications' do
        it 'should not alter the updated_at property' do
          expect { subject.save! }.not_to change(subject, :updated_at)
        end
      end
    end
  end
end
